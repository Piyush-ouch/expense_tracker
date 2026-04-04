# Firebase Setup Guide for Expense Tracker Flutter App

## Quick Setup Steps

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your existing Firebase project
3. Enable **Authentication**:
   - Click "Authentication" in the left menu
   - Go to "Sign-in method" tab
   - Enable "Email/Password" provider
   - Click "Save"

4. Enable **Cloud Firestore**:
   - Click "Firestore Database" in the left menu
   - Click "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location
   - Click "Enable"

### 2. Add Android App to Firebase

1. In Firebase Console, click the gear icon → "Project settings"
2. Scroll down to "Your apps" section
3. Click the Android icon to add an Android app
4. Fill in the form:
   - **Android package name**: `com.example.expense_tracker_flutter`
   - **App nickname**: Expense Tracker (optional)
   - **Debug signing certificate SHA-1**: (optional for now)
5. Click "Register app"
6. Download the `google-services.json` file
7. **IMPORTANT**: Place `google-services.json` in:
   ```
   expense_tracker_flutter/android/app/google-services.json
   ```

### 3. Test the Setup

Run the following commands:

```bash
cd expense_tracker_flutter
flutter pub get
flutter run
```

### 4. Firestore Security Rules (Optional for Development)

For development, you can use these test rules in Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /expenses/{expenseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /incomes/{incomeId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 5. For iOS (Optional)

If you want to build for iOS:

1. In Firebase Console, click the iOS icon to add an iOS app
2. Fill in the form:
   - **iOS bundle ID**: `com.example.expenseTrackerFlutter`
   - **App nickname**: Expense Tracker iOS (optional)
3. Download the `GoogleService-Info.plist` file
4. Place it in:
   ```
   expense_tracker_flutter/ios/Runner/GoogleService-Info.plist
   ```

## Troubleshooting

### Error: "No Firebase App '[DEFAULT]' has been created"
- Make sure `google-services.json` is in the correct location
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Error: "MissingPluginException"
- Run `flutter clean`
- Delete the `build` folder
- Run `flutter pub get`
- Restart your IDE

### Authentication not working
- Verify Email/Password is enabled in Firebase Console
- Check that you're using the correct Firebase project
- Make sure Firestore is enabled

## Next Steps

1. Place your `google-services.json` file in `android/app/`
2. Run `flutter pub get`
3. Run `flutter run` on an emulator or device
4. Register a new user
5. Start tracking expenses!

## Data Structure

The app will automatically create this structure in Firestore:

```
users/
  {userId}/
    - name
    - email
    - base_currency
    - display_symbol
    - created_at
    - profile_pic
    
    expenses/
      {expenseId}/
        - amount
        - base_amount
        - original_currency
        - category
        - description
        - date
        - created_at
        - type: "expense"
    
    incomes/
      {incomeId}/
        - amount
        - base_amount
        - original_currency
        - source
        - date
        - created_at
        - type: "income"
```

All amounts are stored as integers (cents) to avoid floating-point precision issues.
