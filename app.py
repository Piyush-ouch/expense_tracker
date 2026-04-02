import os
import json
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore, messaging

# --- CONFIGURATION & INITIALIZATION ---
FIREBASE_KEY_PATH = 'serviceAccountKey.json' 

app = Flask(__name__)

# Firebase initialization
try:
    if os.getenv('FIREBASE_CREDENTIALS'):
        # Production: Load from environment variable
        firebase_creds = json.loads(os.getenv('FIREBASE_CREDENTIALS'))
        cred = credentials.Certificate(firebase_creds)
    else:
        # Local development: Load from file
        cred = credentials.Certificate(FIREBASE_KEY_PATH)
        
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase Admin SDK Initialized Successfully.")
except FileNotFoundError:
    print(f"❌ ERROR: Firebase key file not found at {FIREBASE_KEY_PATH}")
    exit()
except Exception as e:
    print(f"❌ ERROR during Firebase initialization: {e}")
    exit()


# --- FCM NOTIFICATIONS API ---
@app.route('/api/send_push', methods=['POST'])
def send_push():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Invalid JSON data'}), 400
            
        target_uid = data.get('targetUid')
        amount = data.get('amount')
        description = data.get('description')
        sender_name = data.get('senderName', 'A friend')

        if not target_uid:
            return jsonify({'error': 'Missing targetUid'}), 400

        # Safely fetch target user's FCM token from Firestore
        user_doc = db.collection('users').document(target_uid).get()
        if not user_doc.exists:
            return jsonify({'error': 'User not found in database'}), 404
            
        user_data = user_doc.to_dict()
        fcm_token = user_data.get('fcm_token')
        
        if not fcm_token:
            return jsonify({'error': 'User does not have an FCM token registered'}), 400

        # Construct highly visible FCM message
        message = messaging.Message(
            notification=messaging.Notification(
                title='New Split Request!',
                body=f'{sender_name} requested a split of ${amount} for: {description}',
            ),
            data={
                'type': 'split_request',
                'amount': str(amount),
                'description': str(description)
            },
            token=fcm_token,
        )

        response = messaging.send(message)
        print(f"Successfully sent FCM push message: {response}")
        return jsonify({'success': True, 'message_id': response}), 200

    except Exception as e:
        print(f"Error sending FCM push: {e}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Start the Flask app pointing to the global interface
    app.run(host='0.0.0.0', debug=True, port=8000)