import os
from datetime import datetime, timedelta
from flask import Flask, render_template, request, redirect, url_for, session, jsonify
import firebase_admin
from firebase_admin import credentials, firestore, auth
from functools import wraps
import calendar
from werkzeug.utils import secure_filename

# --- CONFIGURATION & INITIALIZATION ---

FIREBASE_KEY_PATH = 'serviceAccountKey.json' 
CURRENCY_API_KEY = 'YOUR_MOCK_API_KEY' 

app = Flask(__name__)
app.jinja_env.globals['now'] = datetime.utcnow 
app.secret_key = os.urandom(24) 

# Configuration for Profile Pictures
UPLOAD_FOLDER = 'static/profile_pics'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max upload size

# Ensure the upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

CURRENCIES = {
    'USD': {'symbol': '$', 'name': 'US Dollar'},
    'INR': {'symbol': '₹', 'name': 'Indian Rupee'},
    'EUR': {'symbol': '€', 'name': 'Euro'},
    'GBP': {'symbol': '£', 'name': 'British Pound'},
    'JPY': {'symbol': '¥', 'name': 'Japanese Yen'},
}
EXPENSE_CATEGORIES = ['Food & Drink', 'Transportation', 'Housing', 'Bills', 'Shopping', 'Entertainment', 'Other']
INCOME_SOURCES = ['Salary', 'Freelance', 'Investment', 'Gift', 'Other']


# --- FIREBASE INITIALIZATION ---
try:
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


# --- HELPER FUNCTIONS ---

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'uid' not in session:
            return redirect(url_for('home'))
        return f(*args, **kwargs)
    return decorated_function

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_exchange_rate(from_currency, to_currency):
    if from_currency == to_currency:
        return 1.0
    MOCK_RATES_TO_USD = {
        'EUR': 1.08, 'INR': 0.012, 'GBP': 1.25, 'JPY': 0.0067, 'USD': 1.0
    }
    rate_from_to_usd = MOCK_RATES_TO_USD.get(from_currency, 1.0)
    rate_to_usd_to_target = 1.0 / MOCK_RATES_TO_USD.get(to_currency, 1.0)
    return rate_from_to_usd * rate_to_usd_to_target

def get_date_range(filter_type, year, month, day=None):
    now = datetime.now()
    if filter_type == 'week':
        if day is None:
            target_date = now
        else:
            try:
                target_date = datetime(year, month, day if day else 1)
            except:
                target_date = now
        start_date = target_date - timedelta(days=target_date.weekday())
        start_date = start_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=6, hours=23, minutes=59, seconds=59)
        return start_date, end_date
    elif filter_type == 'year':
        start_date = datetime(year, 1, 1)
        end_date = datetime(year, 12, 31, 23, 59, 59)
        return start_date, end_date
    else:
        last_day = calendar.monthrange(year, month)[1]
        start_date = datetime(year, month, 1)
        end_date = datetime(year, month, last_day, 23, 59, 59)
        return start_date, end_date


# --- ROUTES: AUTHENTICATION ---

@app.route('/')
def home():
    if 'uid' in session:
        return redirect(url_for('dashboard'))
    return render_template('login.html', currencies=CURRENCIES)

@app.route('/register', methods=['POST'])
def register():
    email = request.form.get('email')
    password = request.form.get('password')
    name = request.form.get('name')
    currency_code = request.form.get('currency')
    
    if not all([email, password, name, currency_code]):
        return render_template('login.html', error="Please fill all fields.", currencies=CURRENCIES)

    try:
        user = auth.create_user(email=email, password=password, display_name=name)
        uid = user.uid
        currency_info = CURRENCIES.get(currency_code, {'symbol': '$'})
        display_symbol = currency_info['symbol']
        
        db.collection('users').document(uid).set({
            'name': name,
            'email': email,
            'base_currency': currency_code,
            'display_symbol': display_symbol,
            'created_at': firestore.SERVER_TIMESTAMP,
            'profile_pic': None # Initialize with no picture
        })
        
        session['uid'] = uid
        session['name'] = name
        return redirect(url_for('dashboard'))

    except firebase_admin.exceptions.AlreadyExistsError:
        return render_template('login.html', error="Email address is already in use.", currencies=CURRENCIES)
    except Exception as e:
        print(f"Registration Error: {e}")
        return render_template('login.html', error=f"Registration failed: {str(e)}", currencies=CURRENCIES)


@app.route('/login', methods=['POST'])
def login():
    id_token = request.form.get('idToken')
    
    if not id_token:
        return render_template('login.html', error="Authentication token missing.", currencies=CURRENCIES)

    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        session['uid'] = uid
        session['name'] = decoded_token.get('name', 'User')
        
        return redirect(url_for('dashboard'))

    except Exception as e:
        print(f"Login Error: {e}")
        return render_template('login.html', error="Invalid credentials", currencies=CURRENCIES)


# --- CHARTS ROUTE ---
@app.route('/charts')
@login_required
def charts():
    uid = session['uid']
    now = datetime.now()
    filter_type = request.args.get('filter', 'month')
    
    try:
        selected_year = int(request.args.get('year', now.year))
        selected_month = int(request.args.get('month', now.month))
        selected_day = int(request.args.get('day', now.day))
    except ValueError:
        selected_year = now.year
        selected_month = now.month
        selected_day = now.day

    start_date, end_date = get_date_range(filter_type, selected_year, selected_month, selected_day)
    
    if filter_type == 'year':
        period_label = f"{selected_year}"
    elif filter_type == 'week':
        period_label = f"{start_date.strftime('%b %d')} - {end_date.strftime('%b %d')}"
    else:
        period_label = calendar.month_name[selected_month]

    user_ref = db.collection('users').document(uid)

    expenses_query = user_ref.collection('expenses') \
        .where('date', '>=', start_date) \
        .where('date', '<=', end_date) \
        .stream()

    expense_chart_data = {}
    for doc in expenses_query:
        data = doc.to_dict()
        amount = data.get('base_amount', 0)
        cat = data.get('category', 'Other')
        expense_chart_data[cat] = expense_chart_data.get(cat, 0) + amount

    incomes_query = user_ref.collection('incomes') \
        .where('date', '>=', start_date) \
        .where('date', '<=', end_date) \
        .stream()

    income_chart_data = {}
    for doc in incomes_query:
        data = doc.to_dict()
        amount = data.get('base_amount', 0)
        source = data.get('source', 'Other')
        income_chart_data[source] = income_chart_data.get(source, 0) + amount

    return render_template(
        'charts.html',
        expense_chart_data=expense_chart_data,
        income_chart_data=income_chart_data,
        current_filter=filter_type,
        current_year=selected_year,
        current_month=selected_month,
        current_day=selected_day,
        period_label=period_label
    )


# --- DASHBOARD ROUTE ---
@app.route('/dashboard')
@login_required
def dashboard():
    uid = session['uid']
    now = datetime.now()
    
    try:
        selected_month = int(request.args.get('month', now.month))
        selected_year = int(request.args.get('year', now.year))
    except ValueError:
        selected_month = now.month
        selected_year = now.year

    last_day = calendar.monthrange(selected_year, selected_month)[1]
    start_date = datetime(selected_year, selected_month, 1)
    end_date = datetime(selected_year, selected_month, last_day, 23, 59, 59)
    month_name = calendar.month_name[selected_month]

    user_ref = db.collection('users').document(uid)
    user_data = user_ref.get().to_dict()
    display_symbol = user_data.get('display_symbol', '$')

    expenses_query = user_ref.collection('expenses') \
        .where('date', '>=', start_date) \
        .where('date', '<=', end_date) \
        .order_by('date', direction=firestore.Query.DESCENDING).stream()

    total_expense_base = 0
    transactions = []

    for doc in expenses_query:
        data = doc.to_dict()
        data['id'] = doc.id
        transactions.append(data)
        total_expense_base += data.get('base_amount', 0)

    incomes_query = user_ref.collection('incomes') \
        .where('date', '>=', start_date) \
        .where('date', '<=', end_date) \
        .stream()

    total_income_base = 0
    for doc in incomes_query:
        data = doc.to_dict()
        data['id'] = doc.id
        transactions.append(data)
        total_income_base += data.get('base_amount', 0)

    transactions_by_date = {}
    for t in transactions:
        t_date = t['date']
        date_key = t_date.strftime('%Y-%m-%d')
        display_date = t_date.strftime('%b %d %A')
        
        if date_key not in transactions_by_date:
            transactions_by_date[date_key] = {
                'display_date': display_date,
                'date_obj': t_date,
                'daily_income': 0,
                'daily_expense': 0,
                'transaction_list': []
            }
        
        transactions_by_date[date_key]['transaction_list'].append(t)
        
        if t.get('type') == 'expense':
            transactions_by_date[date_key]['daily_expense'] += t.get('base_amount', 0)
        elif t.get('type') == 'income':
            transactions_by_date[date_key]['daily_income'] += t.get('base_amount', 0)

    grouped_transactions = sorted(transactions_by_date.values(), key=lambda x: x['date_obj'], reverse=True)
    net_balance_base = total_income_base - total_expense_base

    return render_template(
        'dashboard.html', 
        display_symbol=display_symbol, 
        name=session.get('name', 'User'),
        grouped_transactions=grouped_transactions, 
        total_income=total_income_base,
        total_expense=total_expense_base,
        net_balance=net_balance_base,
        current_month=selected_month,
        current_year=selected_year,
        month_name=month_name
    )


@app.route('/add_expense', methods=['GET', 'POST'])
@login_required
def add_expense():
    uid = session['uid']
    user_data = db.collection('users').document(uid).get().to_dict()
    base_currency = user_data.get('base_currency', 'USD')
    today_date = datetime.now().strftime('%Y-%m-%d')
    
    if request.method == 'POST':
        try:
            amount = float(request.form.get('amount'))
            original_currency = request.form.get('currency')
            category = request.form.get('category')
            description = request.form.get('description', '')
            date_str = request.form.get('date')
            
            conversion_rate = get_exchange_rate(original_currency, base_currency)
            base_amount = amount * conversion_rate
            
            expense_data = {
                'amount': int(amount * 100), 
                'base_amount': int(base_amount * 100), 
                'original_currency': original_currency,
                'category': category,
                'description': description,
                'date': datetime.strptime(date_str, '%Y-%m-%d'),
                'created_at': firestore.SERVER_TIMESTAMP,
                'type': 'expense'
            }
            
            db.collection('users').document(uid).collection('expenses').add(expense_data)
            return redirect(url_for('dashboard'))

        except Exception as e:
            error = f"Error saving expense: {e}"
            return render_template('add_expense.html', error=error, currencies=CURRENCIES, categories=EXPENSE_CATEGORIES, today=today_date)

    return render_template('add_expense.html', currencies=CURRENCIES, categories=EXPENSE_CATEGORIES, base_currency=base_currency, today=today_date)


@app.route('/add_income', methods=['GET', 'POST'])
@login_required
def add_income():
    uid = session['uid']
    user_data = db.collection('users').document(uid).get().to_dict()
    base_currency = user_data.get('base_currency', 'USD')
    today_date = datetime.now().strftime('%Y-%m-%d')
    
    if request.method == 'POST':
        try:
            amount = float(request.form.get('amount'))
            original_currency = request.form.get('currency')
            source = request.form.get('source')
            date_str = request.form.get('date')
            
            conversion_rate = get_exchange_rate(original_currency, base_currency)
            base_amount = amount * conversion_rate
            
            income_data = {
                'amount': int(amount * 100), 
                'base_amount': int(base_amount * 100), 
                'original_currency': original_currency,
                'source': source,
                'date': datetime.strptime(date_str, '%Y-%m-%d'),
                'created_at': firestore.SERVER_TIMESTAMP,
                'type': 'income'
            }
            
            db.collection('users').document(uid).collection('incomes').add(income_data)
            return redirect(url_for('dashboard'))

        except Exception as e:
            error = f"Error saving income: {e}"
            return render_template('add_income.html', error=error, currencies=CURRENCIES, sources=INCOME_SOURCES, today=today_date)

    return render_template('add_income.html', currencies=CURRENCIES, sources=INCOME_SOURCES, base_currency=base_currency, today=today_date)


# --- PROFILE ROUTE (NEW) ---
@app.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    uid = session['uid']
    user_ref = db.collection('users').document(uid)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        return redirect(url_for('logout'))
        
    user_data = user_doc.to_dict()

    if request.method == 'POST':
        # Handle Profile Pic Upload
        if 'profile_pic' in request.files:
            file = request.files['profile_pic']
            if file and allowed_file(file.filename):
                # Secure the filename and append uid to avoid conflicts
                original_filename = secure_filename(file.filename)
                extension = original_filename.rsplit('.', 1)[1].lower()
                new_filename = f"{uid}.{extension}"
                
                # Save file
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], new_filename))
                
                # Update DB
                user_ref.update({'profile_pic': new_filename})
                return redirect(url_for('profile'))

    # Get profile pic if exists
    profile_pic = user_data.get('profile_pic', None)
    
    return render_template('profile.html', 
                           user_name=user_data.get('name', 'User'),
                           user_email=user_data.get('email', ''),
                           user_currency=user_data.get('base_currency', 'USD'),
                           profile_pic=profile_pic)


# --- LOGOUT ---
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('home'))


if __name__ == '__main__':
    app.run(debug=True, port=8000)