# 🗺️ Google Maps Setup Guide

## Step 1: Get Google Maps API Key

### 1.1 Go to Google Cloud Console
- Open: https://console.cloud.google.com/
- Create a new project or select existing one
- Project name: `blood-bank` (or your choice)

### 1.2 Enable Required APIs
1. Click **"Enable APIs and Services"** button
2. Search for and enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** (if building for iOS)
   - **Distance Matrix API** (for ETA calculation)

### 1.3 Create API Key
1. Go to **Credentials** (left sidebar)
2. Click **"Create Credentials"** → **"API Key"**
3. Copy your API Key (looks like: `AIzaSy_XXXXXXXXXXXXXXXXXXXXX`)
4. ⚠️ **IMPORTANT:** Add restrictions:
   - **Application restrictions:** Android
   - **Package name:** `com.bloodbank` (or your package name)
   - **SHA-1 fingerprint:** Get from `android/app/build.gradle` (keytool command)

---

## Step 2: Add API Key to Android App

### 2.1 Update AndroidManifest.xml
**File:** `android/app/src/main/AndroidManifest.xml`

Find this section (around line 13-15):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy_YOUR_ACTUAL_KEY_HERE"/>
```

### 2.2 Permissions (Already Done ✅)
**File:** `android/app/src/main/AndroidManifest.xml`

These are already present (lines 2-6):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## Step 3: Test Google Maps

### 3.1 Verify Maps Screen Works
1. Run the app
2. Go to **Receiver Dashboard** → Blood Request → Map button (if available)
3. Or go to **Donor Dashboard** → Blood Requests list → tap any request to see map
4. Map should show your location + nearby donors

### 3.2 Test Location Features
- ✅ Current location marker (blue)
- ✅ Nearby donors markers (red)
- ✅ Zoom/pan controls
- ✅ "My Location" button (top right)

---

## ⚠️ Security: Hide Your API Key

### 3.3 DO NOT Commit API Key
The API key should **never** be in version control!

**Current Issue:** 
- Firebase keys are exposed in `lib/firebase_options.dart`
- Google Maps API key will also be exposed if you add it directly

### 3.4 Solution: Use Environment Variables
1. Create a file: `.env.local` (git-ignored)
2. Add: `GOOGLE_MAPS_API_KEY=AIzaSy_YOUR_KEY`
3. Use dart_dotenv package to load it
4. Add to `.gitignore`:
```
.env.local
lib/firebase_options.dart
google-services.json
GoogleService-Info.plist
```

---

## 🔐 Firebase Security Fix

### 4.1 Rotate Firebase Keys Immediately
**Why?** Firebase credentials are exposed in `lib/firebase_options.dart`

1. Go to **Firebase Console** → Project Settings
2. Go to **Service Accounts** tab
3. Delete old keys
4. Generate new ones

### 4.2 Add to .gitignore
```
firebase_options.dart
google-services.json
GoogleService-Info.plist
```

### 4.3 For Next Time: Use FlutterFire CLI
```bash
flutterfire configure
```
This auto-generates secure config without exposing keys.

---

## ✅ Checklist

- [ ] Google Cloud Project created
- [ ] Maps APIs enabled (Android, iOS, Distance Matrix)
- [ ] API Key generated
- [ ] API Key added to AndroidManifest.xml
- [ ] Tested on device/emulator
- [ ] Firebase keys rotated
- [ ] .gitignore updated
- [ ] No keys committed to repo

---

## 🆘 Troubleshooting

### Maps not showing
- ❌ API Key not set → Check AndroidManifest.xml
- ❌ API Key wrong format → Copy again from Google Cloud
- ❌ APIs not enabled → Check Google Cloud console
- ❌ Wrong package name → Verify in build.gradle

### Location not working
- ❌ Permissions not granted → Check device settings
- ❌ GPS turned off → Turn on in emulator/device
- ❌ No internet → Check WiFi/mobile data

### "ProviderNotFoundException"
- ✅ **FIXED** - MultiProvider now in main.dart

---

## 📞 Support
For issues, check:
- Google Cloud Console: https://console.cloud.google.com/
- Firebase Console: https://console.firebase.google.com/
- Flutter Maps docs: https://pub.dev/packages/google_maps_flutter
