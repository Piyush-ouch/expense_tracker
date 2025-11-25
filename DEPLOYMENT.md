# Render Deployment Guide

This guide will help you deploy the Money Tracker app to Render.

## Prerequisites

- GitHub repository (already done ✅)
- Render account (free tier available)
- Firebase service account key JSON

## Deployment Steps

### 1. Prepare Firebase Credentials

Since we can't commit `serviceAccountKey.json` to GitHub, we'll use environment variables on Render:

1. Open your `serviceAccountKey.json` file
2. Copy the entire JSON content
3. You'll paste this as an environment variable on Render

### 2. Create Web Service on Render

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository: `Piyush-ouch/expense_tracker`
4. Configure the service:
   - **Name**: `expense-tracker` (or your preferred name)
   - **Region**: Choose closest to you
   - **Branch**: `main`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app`
   - **Instance Type**: `Free`

### 3. Set Environment Variables

In the Render dashboard, add these environment variables:

1. **FIREBASE_CREDENTIALS** (Critical!)
   - Value: Paste your entire `serviceAccountKey.json` content
   - This is a JSON string

2. **PYTHON_VERSION** (Optional)
   - Value: `3.11.0`

### 4. Modify app.py for Production

The app needs to read Firebase credentials from environment variable instead of file.

Add this code at the top of `app.py` (after imports):

```python
import json
import os

# Firebase initialization for production
if os.getenv('FIREBASE_CREDENTIALS'):
    # Production: Load from environment variable
    firebase_creds = json.loads(os.getenv('FIREBASE_CREDENTIALS'))
    cred = credentials.Certificate(firebase_creds)
else:
    # Local development: Load from file
    cred = credentials.Certificate('serviceAccountKey.json')
```

### 5. Deploy

1. Click **"Create Web Service"**
2. Render will automatically:
   - Clone your repository
   - Install dependencies
   - Start the application
3. Wait for deployment (2-5 minutes)
4. Your app will be live at: `https://your-app-name.onrender.com`

## Important Notes

⚠️ **Free Tier Limitations:**
- App spins down after 15 minutes of inactivity
- First request after spin-down takes 30-60 seconds
- 750 hours/month free

✅ **After Deployment:**
- Test login/signup
- Add a test transaction
- Verify Firebase connection
- Check charts page

## Troubleshooting

**Build fails:**
- Check `requirements.txt` has all dependencies
- Verify Python version in `runtime.txt`

**App crashes:**
- Check Render logs for errors
- Verify Firebase credentials are set correctly
- Ensure environment variable is valid JSON

**Firebase errors:**
- Double-check `FIREBASE_CREDENTIALS` environment variable
- Verify Firebase project has Firestore enabled
- Check authentication is enabled

## Custom Domain (Optional)

1. Go to your service settings
2. Click "Custom Domain"
3. Add your domain and follow DNS instructions

---

Need help? Check [Render Documentation](https://render.com/docs)
