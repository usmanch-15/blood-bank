# Blood Bank - Flutter Mobile Application

A comprehensive Flutter mobile application for managing blood donations and requests, built as a Final Year Project.

## Features

### Core Modules

1. **Authentication Module**
   - Firebase Authentication
   - Email/Password login
   - Sign up with OTP verification support
   - Role selection (Donor / Receiver / Admin)

2. **Donor Module**
   - Donor profile management
   - Donation history tracking
   - Eligibility checking (90-day minimum between donations)
   - Reward points system
   - Certificates and badges

3. **Receiver Module**
   - Create blood requests
   - SOS emergency button for urgent situations
   - Request management
   - View request status

4. **Admin Module**
   - View all users
   - View all blood requests
   - Dashboard statistics
   - Manage request status

5. **Mapping Module**
   - Google Maps integration (requires API key setup)
   - Show nearby donors
   - Distance calculation

6. **Notification Module**
   - Firebase Cloud Messaging integration
   - SOS alerts
   - Eligibility reminders

## Project Structure

```
lib/
├── constants/          # App constants, colors, theme
├── models/            # Data models (User, Donation, BloodRequest)
├── screens/           # All app screens
│   ├── auth/         # Authentication screens
│   ├── donor/        # Donor module screens
│   ├── receiver/     # Receiver module screens
│   ├── admin/        # Admin module screens
│   └── maps/         # Mapping screens
├── services/          # Firebase services (Auth, Firestore)
├── utils/            # Utility classes (Eligibility, Location)
└── widgets/          # Reusable UI components
```

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Android Studio / VS Code with Flutter extensions
- Firebase account

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore Database
   - Enable Cloud Messaging (FCM)

2. **Add Firebase to Android**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/` directory
   - Update `android/build.gradle`:
     ```gradle
     dependencies {
         classpath 'com.google.gms:google-services:4.4.0'
     }
     ```
   - Update `android/app/build.gradle`:
     ```gradle
     apply plugin: 'com.google.gms.google-services'
     ```

3. **Firestore Rules**
   - Set up Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         allow read: if request.auth != null;
       }
       match /blood_requests/{requestId} {
         allow read, write: if request.auth != null;
       }
       match /donations/{donationId} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### Google Maps Setup

1. **Get API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Maps SDK for Android/iOS
   - Create API key

2. **Add to Android**
   - Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application>
       <meta-data
           android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_API_KEY_HERE"/>
   </application>
   ```

### Installation Steps

1. **Clone/Download the project**

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Build for Release

### Android APK

```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

## Default Users

The app uses Firebase Authentication. You'll need to:
1. Create accounts through the Sign Up screen
2. Select a role (Donor/Receiver)
3. For admin access, manually update the role in Firestore to 'admin'

## Important Notes

- **Firebase Configuration**: Make sure to add your Firebase config files before running
- **Google Maps API Key**: Required for mapping features
- **Permissions**: The app requires location permissions for donor mapping
- **Internet Connection**: Required for Firebase operations

## Code Structure

### Clean Architecture

The project follows clean architecture principles:
- **Models**: Data structures
- **Services**: Business logic and Firebase operations
- **Screens**: UI components
- **Widgets**: Reusable UI components
- **Utils**: Helper functions

### State Management

Currently using Provider pattern. Can be extended with:
- Riverpod
- Bloc
- GetX

## Features Implementation Status

✅ Authentication (Email/Password)
✅ User Profile Management
✅ Donor Dashboard
✅ Receiver Dashboard
✅ Blood Request Creation
✅ SOS Emergency
✅ Admin Dashboard
✅ Donation History
✅ Rewards System
🔄 Google Maps (requires API key setup)
🔄 Push Notifications (FCM setup required)

## Contributing

This is a Final Year Project. For improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is created for educational purposes as a Final Year Project.

## Support

For issues or questions, please create an issue in the repository.

---

**Note**: Remember to configure Firebase and Google Maps API keys before building for production!
