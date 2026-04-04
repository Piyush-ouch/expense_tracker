<p align="center">
  <img src="expense_tracker_flutter/assets/app_icon.png" alt="Kharcha Pani Logo" width="150" height="150" style="border-radius: 30px;" />
</p>

<h1 align="center">💰 Kharcha Pani — Expense Tracker</h1>

<p align="center">
  <em>A modern, full-stack expense tracking app built with Flutter & Flask, powered by Firebase.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Flask-Python-000000?logo=flask&logoColor=white" alt="Flask" />
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License" />
</p>

---

## 📖 About

**Kharcha Pani** (कर्चा पानी - "Expenses & Water", a Hindi/Nepali expression for daily spending) is a feature-rich personal finance app that helps you effortlessly track expenses, income, and split bills with friends. It automatically reads your UPI/banking SMS messages to categorize transactions — no manual entry needed!

---

## ✨ Features

### 🔐 Authentication & Onboarding
- **Email/Password Authentication** — Secure sign-up and login via Firebase Auth
- **Animated Onboarding** — Beautiful wallet card animation on first launch
- **Splash Screen** — Smooth app launch experience
- **Auto Session Management** — Stay logged in across sessions

### 📊 Dashboard
- **Monthly Overview** — Total balance, income, and expenses at a glance
- **Premium Balance Card** — Silver gradient card with credit card design aesthetic
- **Transaction History** — All transactions grouped by date with daily totals
- **Month/Year Navigation** — Browse through any month with the built-in picker
- **Search** — Instantly search transactions by category or description
- **Real-time Sync** — Data updates live via Firestore streams

### 💸 Expense Management
- **Quick Expense Entry** — Add expenses with amount, category, date, and description
- **7 Categories** — Food & Drink, Transportation, Housing, Bills, Shopping, Entertainment, Other
- **Multi-Currency Support** — USD ($), INR (₹), EUR (€), GBP (£), JPY (¥)
- **Auto Currency Conversion** — Automatic conversion to your base currency
- **Long-press to Delete** — Remove transactions with a simple gesture

### 💰 Income Tracking
- **Record Income** — Track income from multiple sources
- **5 Income Sources** — Salary, Freelance, Investment, Gift, Other
- **Multi-Currency** — Same currency support as expenses with auto-conversion
- **Date Tracking** — Set any date for the income entry

### 📱 Automatic SMS Transaction Sync
- **UPI/Banking SMS Parsing** — Automatically reads SMS from banks like SBI, HDFC, ICICI, Axis, Kotak, PNB, etc.
- **Smart Transaction Detection** — Detects debits & credits from keywords like "debited", "credited", "paid", etc.
- **Auto-Categorization** — Recognizes merchants (Zomato → Food, Amazon → Shopping, Uber → Transport, Netflix → Entertainment, etc.)
- **Duplicate Detection** — Skips already-synced transactions
- **Background SMS Receiver** — Native Kotlin BroadcastReceiver captures transactions in real-time, even when app is closed
- **Manual SMS Scan** — Scan past 3-12 months of SMS on demand
- **Promotional SMS Filtering** — Ignores OTP, recharge, and promotional messages

### 🤝 Split Expenses (Kharcha Pani Split)
- **Split Bills with Friends** — Send split requests to any registered user
- **Contact Picker** — Pick friends directly from your phone contacts
- **Phone Number Lookup** — Find users by their registered phone number
- **Real-time In-App Notifications** — Firestore listener shows split requests instantly in-app
- **Accept/Decline** — Friends can accept or decline split requests with one tap
- **Self-Protection** — Prevents splitting with yourself

### 🔔 Push Notifications (FCM)
- **Firebase Cloud Messaging** — Push notifications for split expense requests
- **Flask Backend Integration** — Backend triggers FCM via Firebase Admin SDK
- **Foreground + Background Notifications** — Local notifications shown via `flutter_local_notifications`
- **Custom Notification Channel** — Dedicated "Split Requests" channel on Android
- **FCM Token Management** — Token auto-refreshes and clears on logout (prevents cross-account leakage)

### 📈 Analytics & Charts
- **Interactive Pie Charts** — Visual breakdown of spending by category (powered by `fl_chart`)
- **Income vs Expense Toggle** — Switch between expense categories and income sources
- **Time Filters** — View analytics by Week, Month, or Year
- **Percentage Breakdown** — See exact percentage and amount per category

### 👤 User Profile
- **Profile Picture Upload** — Gallery image picker with Firebase Storage upload
- **Account Info** — Name, email, base currency, and join date
- **Phone Number** — Add/edit phone number for split expense discoverability
- **Lifetime Statistics** — Total income and total expenses across all time
- **Secure Logout** — Clears FCM token on logout to prevent notification hijacking

### 🎨 UI/UX
- **Dark Theme** — Sleek, modern dark interface throughout the app
- **Premium Design** — Gradient balance card, custom animations, glowing loaders
- **Bottom Navigation** — Records, Charts, Reports, and Profile tabs with centered FAB
- **Animated Onboarding** — Slide and fade animations with decorative sparkles
- **Custom Glowing Loader** — Branded loading animation

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter (Dart) |
| **Backend API** | Flask (Python) |
| **Database** | Cloud Firestore |
| **Authentication** | Firebase Auth (Email/Password) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **File Storage** | Firebase Storage |
| **Charts** | fl_chart |
| **State Management** | Provider |
| **SMS Parsing** | Native Kotlin BroadcastReceiver |
| **Deployment** | Render (Flask backend) |

---

## 📁 Project Structure

```
expense-tracker-flask/
├── app.py                          # Flask backend (FCM push API + health check)
├── requirements.txt                # Python dependencies
├── Procfile                        # Render deployment config
├── runtime.txt                     # Python runtime version
├── DEPLOYMENT.md                   # Deployment guide
├── README.md                       # This file
│
└── expense_tracker_flutter/        # Flutter mobile app
    ├── lib/
    │   ├── main.dart               # App entry point, FCM setup
    │   ├── firebase_options.dart   # Firebase config
    │   ├── models/
    │   │   ├── user_model.dart     # User data model
    │   │   ├── expense_model.dart  # Expense data model
    │   │   ├── income_model.dart   # Income data model
    │   │   └── parsed_transaction.dart  # SMS parsed transaction model
    │   ├── screens/
    │   │   ├── auth/
    │   │   │   ├── login_screen.dart
    │   │   │   └── register_screen.dart
    │   │   ├── splash_screen.dart
    │   │   ├── onboarding_screen.dart
    │   │   ├── dashboard_screen.dart
    │   │   ├── add_expense_screen.dart
    │   │   ├── add_income_screen.dart
    │   │   ├── charts_screen.dart
    │   │   ├── profile_screen.dart
    │   │   ├── split_expense_screen.dart
    │   │   └── sms_sync_screen.dart
    │   ├── services/
    │   │   ├── auth_service.dart
    │   │   ├── firestore_service.dart
    │   │   ├── storage_service.dart
    │   │   ├── sms_parser_service.dart
    │   │   └── transaction_sync_service.dart
    │   ├── utils/
    │   │   ├── constants.dart      # Currencies, categories, exchange rates
    │   │   └── theme.dart          # App-wide dark theme
    │   └── widgets/
    │       └── glowing_loader.dart # Custom loading animation
    ├── android/
    │   └── app/src/main/kotlin/.../
    │       └── SmsReceiver.kt      # Native SMS BroadcastReceiver
    └── assets/
        └── app_icon.png            # App launcher icon
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Python 3.11+
- Firebase project with Firestore, Auth, FCM, and Storage enabled
- Android device/emulator

### 1. Clone the Repository

```bash
git clone https://github.com/Piyush-ouch/expense_tracker.git
cd expense_tracker
```

### 2. Flutter App Setup

```bash
cd expense_tracker_flutter
flutter pub get
```

**Firebase Configuration:**
1. Create/select a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable **Email/Password** authentication
3. Enable **Cloud Firestore** database
4. Enable **Cloud Messaging** (FCM)
5. Enable **Firebase Storage**
6. Add an Android app with package name `com.example.expense_tracker_flutter`
7. Download `google-services.json` → place in `android/app/`

```bash
flutter run
```

### 3. Flask Backend Setup (for push notifications)

```bash
# From the project root
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS/Linux

pip install -r requirements.txt
```

Place your Firebase `serviceAccountKey.json` in the project root, then:

```bash
python app.py
```

The backend runs at `http://localhost:8000` with:
- `POST /api/send_push` — Send FCM push notification for split requests
- `GET /api/health` — Health check endpoint

---

## 🌍 Supported Currencies

| Currency | Symbol | Name |
|----------|--------|------|
| USD | $ | US Dollar |
| INR | ₹ | Indian Rupee |
| EUR | € | Euro |
| GBP | £ | British Pound |
| JPY | ¥ | Japanese Yen |

---

## 📂 Firebase Data Structure

```
users/{userId}
  ├── name, email, base_currency, display_symbol
  ├── phone_number, profile_pic, fcm_token
  ├── created_at
  ├── expenses/{expenseId}
  │     ├── amount, base_amount (cents)
  │     ├── original_currency, category, description
  │     └── date, created_at
  └── incomes/{incomeId}
        ├── amount, base_amount (cents)
        ├── original_currency, source
        └── date, created_at

split_requests/{requestId}
  ├── from_uid, to_uid
  ├── amount, description
  ├── status (pending/accepted/declined)
  └── created_at
```

---

## 🔒 Security

- 🔑 Firebase Authentication for secure login/registration
- 🔐 Service account credentials kept private (`.gitignore`)
- 🧱 User data isolated per account in Firestore
- 🔔 FCM tokens cleared on logout to prevent notification hijacking
- 📱 SMS data processed locally — never sent to external servers

---

## 📦 Key Dependencies

### Flutter
| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | User authentication |
| `cloud_firestore` | Real-time database |
| `firebase_storage` | Profile picture storage |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Foreground notification display |
| `fl_chart` | Pie charts & analytics |
| `provider` | State management |
| `intl` | Date/currency formatting |
| `image_picker` | Profile picture upload |
| `flutter_contacts` | Contact picker for splits |
| `http` | Backend API calls |

### Python (Flask)
| Package | Purpose |
|---------|---------|
| `flask` | Web framework |
| `firebase-admin` | Firebase Admin SDK for FCM |
| `gunicorn` | Production WSGI server |

---

## 👨‍💻 Author

**Piyush** — [@Piyush-ouch](https://github.com/Piyush-ouch)

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## ⭐ Show Your Support

Give a ⭐️ if this project helped you!
