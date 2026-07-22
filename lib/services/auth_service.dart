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
        password: password.trim(),
      );

      // ✅ Email verification check — before this fix, unverified emails
      // (typos, fake addresses) could log in and use the app normally.
      await credential.user!.reload();
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw 'email-not-verified';
      }

      // Firestore se status check karo
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (doc.exists) {
        final status = doc.data()?['status'] ?? 'pending';

        if (status == 'pending') {
          await _auth.signOut();
          throw 'pending';
        }

        if (status == 'rejected') {
          await _auth.signOut();
          throw 'rejected';
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ Signup — status 'pending' ke saath save karo
  Future<UserCredential> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? bloodGroup,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Firestore mein user data save karo — status: pending
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'phoneNumber': phoneNumber,
        'bloodGroup': bloodGroup,
        'status': 'pending',   // ← admin approval required
        'isEligible': true,
        'rewardPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastDonationDate': null,
        'location': null,
        'latitude': null,
        'longitude': null,
        'profileImageUrl': null,
      });

      // ✅ Send verification email — user must click the link before they
      // can log in (enforced in signInWithEmailPassword above).
      await credential.user!.sendEmailVerification();

      // Turant logout — pehle email verify, phir admin approve kare tab tak wait
      await _auth.signOut();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
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
        password: password.trim(),
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

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked') {
        // Number pehle se hi is account se linked hai — treat as success
        return;
      }
      if (e.code == 'invalid-verification-code') {
        throw Exception('Code galat hai. Dobara check karein.');
      }
      throw Exception(_handleAuthError(e));
    }
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