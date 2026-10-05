# Maps and Firebase setup

This guide was introduced on `fix/google-maps-setup`. The application has since
migrated from Google Maps to `flutter_map` (OpenStreetMap) and OSRM routing.
Follow the current setup below; a Google Maps API key and Distance Matrix API
subscription are not required by this project.

## Maps and location

1. Install the locked Flutter dependencies with `flutter pub get`.
2. Run the application on an Android device or emulator with internet access.
3. Grant location permission when prompted and enable the device's location
   service. Configure a simulated location when testing on an emulator.
4. Sign in with an approved account and open the nearby-donor map from the
   receiver dashboard.
5. Check map tiles, current location, donor search, and route estimates.

Donor results depend on the application's account, eligibility, availability,
and location-sharing rules. An empty result is not necessarily a map failure.
The map uses approximate donor locations; retain the existing privacy controls.
OSRM estimates require network access and can be unavailable independently of
map tiles.

The Android application ID is `com.usmanch.bloodbank`. Its manifest already
declares internet and location permissions. Do not add a Google Maps API key
or replace the existing map implementation as part of setup.

## Firebase configuration

- Use `lib/firebase_options.dart` and `android/app/google-services.json` for
  the intended Firebase project. Confirm the project and platform app IDs
  before connecting a different environment.
- Keep Firebase Authentication, Firestore rules, Storage rules, and backend
  authorization checks aligned with the application. Platform configuration
  files are not a substitute for those access controls.
- Keep service-account private keys, operator credentials, and backend secrets
  out of source control. Do not remove the platform configuration files needed
  by the current Android build merely because an older guide called them
  service-account credentials.
- Backend functions require Node.js 22. Use JDK 17 for Android builds and
  JDK 21 for Firebase emulator tooling.

## Local validation

From the repository root in PowerShell:

```powershell
flutter pub get
npm.cmd ci --prefix functions
flutter analyze
flutter test
npm.cmd --prefix functions run check
npm.cmd --prefix functions test
functions\node_modules\.bin\firebase.cmd emulators:exec --project demo-blood-bank --only firestore,auth,storage "npm.cmd --prefix functions run test:emulator"
flutter build apk --debug
```

Use the emulator instructions in [README.md](README.md) for isolated backend
testing. Do not run emulator tests against a production Firebase project.

## Troubleshooting

- **Tiles do not load:** check internet access and OpenStreetMap tile access.
- **Location is unavailable:** check permissions, device location services,
  and the emulator's simulated location.
- **No donors appear:** verify account approval and donor availability,
  eligibility, location-sharing consent, search radius, and blood-group filters.
- **Driving estimate is unavailable:** check network access to OSRM; map tiles
  and route estimates use separate services.
- **Firebase access is denied:** check the signed-in account, configured project,
  and deployed rules. Do not relax database rules to bypass an access error.
- **Provider errors:** preserve the providers and route guards registered in
  `lib/main.dart`; older mock-auth setup instructions do not apply.
