# Expense Tracker Flutter App

A mobile expense tracking application built with Flutter and Firebase.

## Features

✅ **User Authentication**
- Email/password registration and login
- Automatic session management
- Secure Firebase authentication

✅ **Expense Management**
- Add expenses with multiple currencies
- Categorize expenses (Food & Drink, Transportation, Housing, Bills, Shopping, Entertainment, Other)
- Add descriptions and dates
- Automatic currency conversion

✅ **Income Tracking**
- Record income from multiple sources (Salary, Freelance, Investment, Gift, Other)
- Multi-currency support
- Date tracking

✅ **Dashboard**
- Monthly overview of income, expenses, and balance
- Transaction history grouped by date
- Month/year navigation
- Long-press to delete transactions

✅ **Analytics & Charts**
- Pie charts for expense categories
- Pie charts for income sources
- Filter by week, month, or year
- Visual breakdown with percentages

✅ **User Profile**
- View account information
- Display base currency
- Profile picture upload (coming soon)
- Account statistics

## Firebase Setup

### Prerequisites
1. A Firebase project (you can use your existing one)
2. Flutter SDK installed
3. Android Studio or Xcode for mobile development

### Step 1: Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your existing project or create a new one
3. Enable **Authentication** with Email/Password sign-in method
4. Enable **Cloud Firestore** database

### Step 2: Add Android App (if building for Android)

1. In Firebase Console, click "Add app" → Android
2. Register app with package name: `com.example.expense_tracker_flutter`
3. Download `google-services.json`
4. Place it in: `expense_tracker_flutter/android/app/google-services.json`

### Step 3: Add iOS App (if building for iOS)

1. In Firebase Console, click "Add app" → iOS
2. Register app with bundle ID: `com.example.expenseTrackerFlutter`
3. Download `GoogleService-Info.plist`
4. Place it in: `expense_tracker_flutter/ios/Runner/GoogleService-Info.plist`

### Step 4: Update Android Configuration

Edit `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Edit `android/app/build.gradle`:
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

## Installation

1. Navigate to the project directory:
```bash
cd expense_tracker_flutter
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── expense_model.dart
│   └── income_model.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── add_expense_screen.dart
│   ├── add_income_screen.dart
│   ├── charts_screen.dart
│   └── profile_screen.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   └── firestore_service.dart
└── utils/                    # Utilities
    ├── constants.dart
    └── theme.dart
```

## Supported Currencies

- USD (US Dollar) - $
- INR (Indian Rupee) - ₹
- EUR (Euro) - €
- GBP (British Pound) - £
- JPY (Japanese Yen) - ¥

## Firebase Data Structure

### Users Collection
```
users/{userId}
  - name: string
  - email: string
  - base_currency: string
  - display_symbol: string
  - created_at: timestamp
  - profile_pic: string (optional)
```

### Expenses Subcollection
```
users/{userId}/expenses/{expenseId}
  - amount: number (in cents)
  - base_amount: number (in cents, converted)
  - original_currency: string
  - category: string
  - description: string
  - date: timestamp
  - created_at: timestamp
  - type: "expense"
```

### Incomes Subcollection
```
users/{userId}/incomes/{incomeId}
  - amount: number (in cents)
  - base_amount: number (in cents, converted)
  - original_currency: string
  - source: string
  - date: timestamp
  - created_at: timestamp
  - type: "income"
```

## Development

### Running on Android Emulator
```bash
flutter emulators --launch <emulator_id>
flutter run
```

### Running on iOS Simulator
```bash
open -a Simulator
flutter run
```

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Dependencies

- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `cloud_firestore` - Database operations
- `firebase_storage` - File storage
- `provider` - State management
- `fl_chart` - Charts and graphs
- `intl` - Date/currency formatting
- `image_picker` - Profile picture upload
- `cached_network_image` - Image caching

## Troubleshooting

### Firebase not initialized
Make sure you've added the Firebase configuration files (`google-services.json` for Android and/or `GoogleService-Info.plist` for iOS) in the correct locations.

### Build errors
Try cleaning the build:
```bash
flutter clean
flutter pub get
flutter run
```

### Authentication errors
Verify that Email/Password authentication is enabled in Firebase Console under Authentication → Sign-in method.

## License

This project is for educational purposes.
