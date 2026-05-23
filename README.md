# 🩸 Smart Blood Bank Mobile Application

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge)

**A Final Year Project – COMSATS University Islamabad, Vehari Campus**  
Department of Computer Science | Session: Spring 2023–2027

*Muhammad Usman (SP23-BCS-046) | Muhammad Hassan (SP23-BCS-038)*  
*Supervisor: Sir Najeeb Ullah Khan*

</div>

---

## 📋 Overview

The **Smart Blood Bank Mobile Application** is a cross-platform mobile solution built with **Flutter** and **Firebase** that connects blood donors and receivers on a single, verified, real-time platform. It replaces slow manual methods (phone calls, WhatsApp groups) with instant geolocation-based donor matching, SOS emergency alerts, and automated eligibility tracking.

> **Problem:** Hospitals in Pakistan still rely on informal methods to find blood donors during emergencies — causing dangerous delays.  
> **Solution:** A unified app where donors register, receivers request blood, and the system automatically finds and notifies the nearest eligible donor within minutes.

---

## ✨ Features

### 🔐 Authentication Module
- Email/Password login with Firebase Authentication
- OTP-based phone number verification
- Role selection: **Donor**, **Receiver**, or **Admin**
- Admin approval workflow (status: pending → approved)
- Password reset via email

### 🩸 Donor Module
- Register blood group, location, and profile details
- Automatic eligibility check (90-day minimum between donations)
- View complete donation history with dates and locations
- Reward points earned per donation
- Auto-generated downloadable PDF donation certificates
- Toggle availability (Available / Unavailable)

### 🏥 Receiver Module
- Submit structured blood requests (blood group, urgency, hospital, units)
- **SOS Emergency Alert** — instantly notifies all nearby eligible donors
- Auto-expands search radius from 15 km → 30 km if no donors found
- Real-time request status tracking

### 🛡️ Admin Module
- View and manage all registered users
- Approve, suspend, or delete accounts
- Monitor all blood requests and donations
- Dashboard statistics: total donors, receivers, requests, donations

### 🗺️ Mapping Module
- Google Maps integration for live donor locations
- Haversine formula-based distance calculation
- Distance Matrix API for estimated travel time (ETA)

### 🔔 Notification Module
- Firebase Cloud Messaging (FCM) push notifications
- SOS emergency alerts to nearby donors
- Eligibility reminders (when donor becomes eligible again)
- Blood drive announcements

---

## 🏗️ Project Structure

```
smart_blood_bank/
├── lib/
│   ├── app/                    # App config: routes, theme, strings
│   ├── constants/              # AppConstants, AppColors, AppTheme
│   ├── controllers/            # Business logic (Provider pattern)
│   │   ├── auth_controller.dart
│   │   ├── donor_controller.dart
│   │   ├── receiver_controller.dart
│   │   ├── admin_controller.dart
│   │   ├── notification_controller.dart
│   │   └── reward_controller.dart
│   ├── models/                 # Firestore data models
│   │   ├── user_model.dart
│   │   ├── donor_model.dart
│   │   ├── receiver_model.dart
│   │   ├── donation_model.dart
│   │   ├── blood_request_model.dart
│   │   ├── sos_request_model.dart
│   │   ├── notification_model.dart
│   │   └── reward_model.dart
│   ├── modules/                # Feature-specific widgets
│   │   ├── auth/widgets/
│   │   ├── donor/widgets/
│   │   ├── receiver/widgets/
│   │   ├── notifications/widgets/
│   │   └── rewards/widgets/
│   ├── screens/                # All UI screens
│   │   ├── auth/               # Login, Signup, OTP
│   │   ├── donor/              # Dashboard, Profile, History, Eligibility, Rewards
│   │   ├── receiver/           # Dashboard, Blood Request, SOS
│   │   ├── admin/              # Dashboard, Users, Requests, Analytics
│   │   ├── maps/               # Nearby Donors Map
│   │   └── notification/       # Notification list
│   ├── services/               # Firebase & external API services
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── notification_service.dart
│   │   ├── geo_location_service.dart
│   │   ├── storage_service.dart
│   │   ├── certificate_service.dart
│   │   └── maps_service.dart
│   ├── utils/                  # Helper utilities
│   │   ├── date_utils.dart     # Eligibility calculation (90-day rule)
│   │   └── location_helper.dart # Haversine distance formula
│   ├── widgets/                # Shared reusable widgets
│   └── main.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/
│   ├── unit/
│   └── widget/
├── android/
├── ios/
└── pubspec.yaml
```

---

## 🛠️ Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| Flutter | 3.19+ | Cross-platform mobile UI framework |
| Dart | 3.3+ | Programming language |
| Firebase Authentication | Latest | Email/password & OTP login |
| Firebase Firestore | Latest | Cloud NoSQL database |
| Firebase Cloud Messaging | Latest | Push notifications |
| Firebase Storage | Latest | PDF certificate storage |
| Google Maps API | v2 | Live maps & geolocation |
| Provider | Latest | State management |
| Geolocator | Latest | Device GPS access |
| PDF package | Latest | Certificate generation |

---

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK (latest stable) — [Install Flutter](https://flutter.dev/docs/get-started/install)
- Dart SDK (included with Flutter)
- Android Studio or VS Code with Flutter extension
- A Firebase account — [Firebase Console](https://console.firebase.google.com)
- Google Cloud account for Maps API

---

### Step 1 – Clone the Project

```bash
git clone https://github.com/your-username/smart_blood_bank.git
cd smart_blood_bank
```

---

### Step 2 – Firebase Setup

#### 2.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add Project** → Enter project name
3. Enable **Google Analytics** (optional)

#### 2.2 Enable Firebase Services
In your Firebase project, enable:
- **Authentication** → Sign-in method → Email/Password ✅
- **Cloud Firestore** → Create database → Start in test mode
- **Cloud Messaging** (FCM) ✅
- **Storage** ✅

#### 2.3 Add Android App
1. In Firebase Console → Project Settings → Add App → Android
2. Package name: `com.yourname.smartbloodbank`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### 2.4 Add iOS App (optional)
1. In Firebase Console → Add App → iOS
2. Bundle ID: `com.yourname.smartbloodbank`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

#### 2.5 Update `android/build.gradle`
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

#### 2.6 Update `android/app/build.gradle`
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

### Step 3 – Firestore Security Rules

In Firebase Console → Firestore → Rules, paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /blood_requests/{requestId} {
      allow read, write: if request.auth != null;
    }

    match /donations/{donationId} {
      allow read, write: if request.auth != null;
    }

    match /notifications/{notifId} {
      allow read, write: if request.auth != null;
    }

    match /rewards/{rewardId} {
      allow read, write: if request.auth != null;
    }

    match /sosRequests/{sosId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

### Step 4 – Google Maps API Setup

#### 4.1 Get API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**
3. Enable **Distance Matrix API**
4. Create an API Key → Copy it

#### 4.2 Add to AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

#### 4.3 Add Location Permissions

Inside `<manifest>` tag (before `<application>`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

### Step 5 – Install Dependencies & Run

```bash
# Install all packages
flutter pub get

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

---

## 📦 Build for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)
```bash
flutter build ios --release
```

---

## 👥 User Roles & Access

| Role | Access | How to Get |
|---|---|---|
| **Donor** | Donate blood, view history, rewards | Sign up → Select "Donor" |
| **Receiver** | Request blood, SOS alert | Sign up → Select "Receiver" |
| **Admin** | Manage all users & requests | Manually set `role: admin` in Firestore |

> **Note:** New accounts start with `status: pending`. Admin must approve them before they can log in.

### How to Create First Admin:
1. Sign up with any email
2. Go to Firebase Console → Firestore → `users` collection
3. Find your user document
4. Update: `role: "admin"` and `status: "approved"`
5. Login again

---

## 🗄️ Firestore Database Collections

| Collection | Key Fields |
|---|---|
| `users` | uid, name, email, phoneNumber, role, bloodGroup, latitude, longitude, isEligible, status, rewardPoints |
| `blood_requests` | id, requesterId, bloodGroup, urgency, hospitalName, location, status, createdAt |
| `donations` | id, donorId, donorName, bloodGroup, donationDate, location, pointsEarned |
| `notifications` | id, userId, title, body, type, createdAt, isRead |
| `rewards` | id, donorId, totalPoints, tier, certificates |
| `sosRequests` | id, receiverId, bloodGroup, latitude, longitude, triggerTime, isResolved |

---

## ✅ Feature Status

| Feature | Status |
|---|---|
| Email/Password Authentication | ✅ Complete |
| OTP Phone Verification | ✅ Complete |
| Donor Profile Management | ✅ Complete |
| Donation History | ✅ Complete |
| Eligibility Check (90-day rule) | ✅ Complete |
| Reward Points & Certificates | ✅ Complete |
| Blood Request Form | ✅ Complete |
| SOS Emergency Alert | ✅ Complete |
| Admin Dashboard | ✅ Complete |
| User Approval Workflow | ✅ Complete |
| Google Maps Integration | 🔄 Requires API Key |
| Push Notifications (FCM) | 🔄 Requires FCM Setup |
| Urdu Language Support | 🔜 Planned |
| Hospital Integration | 🔜 Future Work |

---

## ⚠️ Important Notes

- **Firebase config files** (`google-services.json`, `GoogleService-Info.plist`) are NOT included in the repo for security. Add your own.
- **Google Maps API Key** must be configured before mapping features work.
- **Internet connection** is required for all Firebase operations.
- **Location permission** must be granted by the user for donor matching.
- API keys should never be committed to version control — use environment variables.

---

## 📁 Key Files Reference

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point |
| `lib/constants/app_constants.dart` | Blood groups, collection names, radii |
| `lib/services/auth_service.dart` | All Firebase Auth operations |
| `lib/services/geo_location_service.dart` | GPS + nearby donor search |
| `lib/utils/date_utils.dart` | 90-day eligibility calculation |
| `lib/utils/location_helper.dart` | Haversine distance formula |
| `lib/controllers/` | All business logic (Provider) |
| `lib/models/` | Firestore data models |

---

## 📚 Academic Context

This application was developed as a **Final Year Project** for the degree of **Bachelor of Science in Computer Science** at COMSATS University Islamabad, Vehari Campus.

The project covers concepts from:
- Software Engineering (Agile SDLC, UML diagrams)
- Database Management Systems (Firestore NoSQL)
- Mobile Application Development (Flutter)
- Data Structures & Algorithms (Haversine formula, geo-matching)
- Human-Computer Interaction (Material Design UI)

---

## 📄 License

This project is developed for **educational purposes** as a Final Year Project. Not intended for commercial use.

---

<div align="center">

Made with ❤️ for saving lives | COMSATS University Islamabad, Vehari Campus

</div>
