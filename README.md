# 💰 Money Tracker - Expense Tracker Flask App

A modern, mobile-first expense tracking application built with Flask and Firebase. Track your expenses and income with a beautiful dark-themed interface.

## ✨ Features

- 📊 **Dashboard** - View all transactions organized by date
- 📈 **Charts** - Visualize spending by category with interactive donut charts
- 💸 **Add Expenses** - Quick expense entry with 28+ categories
- 💰 **Add Income** - Track income from multiple sources
- 👤 **Profile** - User profile with avatar upload
- 🔍 **Search** - Search transactions by category or description
- 🌍 **Multi-Currency** - Support for USD, EUR, GBP, INR, JPY
- 🔐 **Firebase Authentication** - Secure user authentication
- 📱 **Mobile-First Design** - Optimized for mobile devices

## 🛠️ Tech Stack

- **Backend**: Flask (Python)
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Frontend**: HTML, CSS, JavaScript
- **Icons**: Font Awesome
- **Charts**: Chart.js

## 📋 Prerequisites

- Python 3.7+
- Firebase account
- Firebase project with Firestore enabled

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/expense-tracker-flask.git
   cd expense-tracker-flask
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firestore Database
   - Enable Email/Password authentication
   - Download your service account key:
     - Go to Project Settings → Service Accounts
     - Click "Generate New Private Key"
     - Save as `serviceAccountKey.json` in the project root

5. **Run the application**
   ```bash
   python app.py
   ```

6. **Open in browser**
   ```
   http://localhost:8000
   ```

## 📁 Project Structure

```
expense-tracker-flask/
├── app.py                 # Main Flask application
├── templates/             # HTML templates
│   ├── login.html        # Login/Signup page
│   ├── dashboard.html    # Main dashboard
│   ├── charts.html       # Charts page
│   ├── add_expense.html  # Add expense modal
│   ├── add_income.html   # Add income modal
│   └── profile.html      # User profile page
├── static/               # Static files
│   ├── js/
│   │   └── main.js      # Firebase client config
│   └── profile_pics/    # User profile pictures
├── serviceAccountKey.json # Firebase credentials (not in repo)
└── requirements.txt      # Python dependencies
```

## 🎨 Features in Detail

### Dashboard
- View all transactions grouped by date
- See daily income/expense totals
- Monthly summary with net balance
- Search functionality
- Month/year navigation

### Charts
- Interactive donut charts
- Toggle between expense and income views
- Category-wise breakdown
- Week/Month/Year filters

### Categories
**Expenses**: Shopping, Food, Phone, Entertainment, Education, Beauty, Sports, Social, Transportation, Clothing, Car, Alcohol, Cigarettes, Electronics, Travel, Health, Pets, Repairs, Housing, Home, Gifts, Donations, Lottery, Snacks, Kids, Vegetables, Fruits, Bills

**Income**: Salary, Investments, Part-Time, Bonus, Others

## 🔒 Security

- Firebase Authentication for secure login
- Service account credentials kept private
- User data isolated in Firestore
- Profile pictures stored securely

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## ⭐ Show your support

Give a ⭐️ if this project helped you!
