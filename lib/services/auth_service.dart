import 'package:flutter/foundation.dart';
import '../utils/account_policy.dart';
import '../utils/validators.dart';
import 'notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Login — status check ke saath
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // ✅ CHANGE: email verification is no longer required to log in.
      // Verification emails are still sent on signup (see signupWithEmail
      // below) for record-keeping / trust, but a user does not need to
      // click that link before using the app — matches the "no approval
      // gate at all" requirement. If verification is ever required again,
      // reinstate a check here using credential.user!.emailVerified.

      await initializeSession();

      // ✅ admin approval is no longer required before login, so this is
      // now how admins see real activity: a timestamp of each user's most
      // recent successful login, shown in AdminWebUsers.
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Signup creates an approved ordinary account; admin is never a signup role.
  Future<UserCredential> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? bloodGroup,
    String? cnic, // ✅ NEW
  }) async {
    if (!const ['donor', 'receiver'].contains(role)) {
      throw ArgumentError('Choose donor or receiver.');
    }
    User? createdUser;
    bool profileSaved = false;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userRef = _firestore.collection('users').doc(credential.user!.uid);
      createdUser = credential.user;
      final batch = _firestore.batch();

      // Firestore mein user data save karo — status: approved
      // ✅ CHANGE: admin approval step removed — new signups get full
      // access immediately (status: 'approved' instead of 'pending').
      // Admin panel now shows lastLoginAt instead, so admins can still
      // see who has actually logged in, without gatekeeping access.
      // ⚠️ SECURITY FIX: phoneNumber ab is top-level doc mein NAHI jata —
      // ye doc `allow read: if isSignedIn()` hai, matlab koi bhi signed-in
      // user kisi ka bhi phone number parh sakta tha. Phone number ab
      // sirf users/{uid}/private/contact mein likha jata hai, jo sirf
      // owner ya admin parh sakte hain (firestore.rules mein pehle se
      // maujood).
      batch.set(userRef, {
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'isDonor': role == 'donor',
        'isReceiver': role == 'receiver',
        'isAvailable': role == 'donor',
        'locationSharingEnabled': false,
        'bloodGroup': bloodGroup,
        'status': 'approved',
        'isEligible': true,
        'rewardPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
        'lastDonationDate': null,
        'location': null,
        'latitude': null,
        'longitude': null,
        'profileImageUrl': null,
      });

      // ✅ NEW — CNIC is stored the same secure way as phoneNumber: in
      // users/{uid}/private/contact, readable only by the owner/admin,
      // never on the top-level user doc that any signed-in user can read.
      if ((phoneNumber != null && phoneNumber.trim().isNotEmpty) ||
          (cnic != null && cnic.trim().isNotEmpty)) {
        batch.set(userRef.collection('private').doc('contact'), {
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
            'phoneNumber': AppValidators.normalizePhone(phoneNumber),
          if (cnic != null && cnic.trim().isNotEmpty) 'cnic': cnic.trim(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      profileSaved = true;

      // Verification email bhejo — sirf record ke liye, ab login isko
      // require nahi karta (signInWithEmailPassword mein check hata diya
      // gaya hai).
      try {
        await credential.user!.sendEmailVerification();
      } on FirebaseAuthException {
        // Account creation succeeded; verification is optional.
      }

      // Signup ke baad sign out — user login screen se khud login karega.
      // Ab koi verification/approval wait nahi, login turant kaam karega.
      await _auth.signOut();

      return credential;
    } catch (e) {
      if (createdUser != null && !profileSaved) {
        try {
          await createdUser.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      if (e is FirebaseAuthException) throw _handleAuthError(e);
      rethrow;
    }
  }

  // ✅ Resend the verification email (used from the "verify your email"
  // screen if the user didn't receive it or it expired).
  // Requires the user to sign in again first since Firebase signs them out
  // right after signup.
  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.reload();
      if (!credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ Firestore se user data lao
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw 'User data load nahi hua: $e';
    }
  }

  // ✅ Firestore mein user data save/update karo
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw 'Data update nahi hua: $e';
    }
  }

  // ✅ Send a phone-number OTP via Firebase Phone Auth.
  // Requires the "Phone" sign-in provider to be enabled in
  // Firebase Console -> Authentication -> Sign-in method.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      if (kIsWeb) {
        final confirmation = await _auth.signInWithPhoneNumber(phoneNumber);
        onCodeSent(confirmation.verificationId);
        return;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          // Android par kabhi kabhi SMS khud-ba-khud verify ho jata hai
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_handleAuthError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout ho gaya, verificationId already onCodeSent se mil chuka hai
        },
      );
    } on FirebaseAuthException catch (e) {
      onError(_handleAuthError(e));
    } catch (e) {
      onError('OTP bhejne mein masla hua: $e');
    }
  }

  // ✅ Verify the entered OTP code and link the phone number to the
  // currently signed-in user (does NOT sign in a new user by itself —
  // it links phone verification to the existing email/password account).
  Future<void> verifyOtpAndLink({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Pehle login karein, phir phone verify karein.');
    }

    await linkVerifiedPhone(credential);
  }

  Future<void> linkVerifiedPhone(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before verifying your phone.');
    if (user.providerData.any((p) => p.providerId == 'phone')) {
      await user.updatePhoneNumber(credential);
    } else {
      await user.linkWithCredential(credential);
    }
    await user.getIdToken(true);
    await user.reload();
    final phone = _auth.currentUser?.phoneNumber;
    if (phone == null) throw StateError('Phone verification did not complete.');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('private')
        .doc('contact')
        .set({'phoneNumber': phone}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> initializeSession() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in.');
    try {
      await user.reload();
      await user.getIdToken(true);
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      final data = doc.data();
      if (!AccountPolicy.isActive(data)) {
        throw StateError('This account is unavailable or suspended.');
      }
      final email = _auth.currentUser?.email;
      if (email != null && email != data!['email']) {
        await doc.reference.update({'email': email});
        data['email'] = email;
      }
      await NotificationService().init();
      return data!;
    } on FirebaseAuthException {
      // Authentication failures such as revoked credentials should end the
      // session. Network/server failures must remain recoverable so a brief
      // outage does not silently sign the user out.
      await _auth.signOut();
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        await _auth.signOut();
      }
      rethrow;
    } catch (e) {
      if (e is StateError && e.toString().contains('unavailable')) {
        await _auth.signOut();
      }
      rethrow;
    }
  }

  Future<void> switchMode(String mode) async {
    final data = await initializeSession();
    if (!AccountPolicy.canSwitchMode(data['role'] as String?, mode)) {
      throw StateError('This account cannot switch to that mode.');
    }
    await updateUserData(_auth.currentUser!.uid, {
      'role': mode,
      if (mode == 'donor') 'isDonor': true,
      if (mode == 'receiver') 'isReceiver': true,
    });
  }

  // ✅ Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ Logout
  Future<void> signOut() async {
    await NotificationService().clearDeviceToken();
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Koi account nahi mila is email se.';
      case 'wrong-password':
        return 'Password galat hai.';
      case 'invalid-credential':
        return 'Email ya password galat hai.';
      case 'email-already-in-use':
        return 'Yeh email pehle se registered hai.';
      case 'invalid-email':
        return 'Email format sahi nahi hai.';
      case 'weak-password':
        return 'Password kam az kam 6 characters ka hona chahiye.';
      case 'network-request-failed':
        return 'Internet connection check karein.';
      default:
        return e.message ?? 'Kuch masla hua. Dobara try karein.';
    }
  }
}
