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

      // ✅ CHANGE: email verification is no longer required to log in.
      // Verification emails are still sent on signup (see signupWithEmail
      // below) for record-keeping / trust, but a user does not need to
      // click that link before using the app — matches the "no approval
      // gate at all" requirement. If verification is ever required again,
      // reinstate a check here using credential.user!.emailVerified.

      // Firestore se status check karo
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      // ⚠️ SECURITY FIX: previously this whole block was `if (doc.exists)`,
      // so a MISSING doc (e.g. an admin-deleted user, or any other way the
      // doc could vanish while the Auth account survives) skipped every
      // check below and fell straight through to `return credential` —
      // i.e. login succeeded with zero restrictions. A real account
      // always has a users/{uid} doc created at signup, so a missing doc
      // now blocks login instead of silently allowing it.
      if (!doc.exists) {
        await _auth.signOut();
        throw 'account-not-found';
      }

      final status = doc.data()?['status'] ?? 'pending';

      if (status == 'pending') {
        await _auth.signOut();
        throw 'pending';
      }

      if (status == 'rejected') {
        await _auth.signOut();
        throw 'rejected';
      }

      if (status == 'deleted') {
        await _auth.signOut();
        throw 'account-not-found';
      }

      // ✅ admin approval is no longer required before login, so this is
      // now how admins see real activity: a timestamp of each user's most
      // recent successful login, shown in AdminWebUsers.
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

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
    String? cnic, // ✅ NEW
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userRef =
      _firestore.collection('users').doc(credential.user!.uid);

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
      await userRef.set({
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
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
        await userRef.collection('private').doc('contact').set({
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
            'phoneNumber': phoneNumber.trim(),
          if (cnic != null && cnic.trim().isNotEmpty)
            'cnic': cnic.trim(),
        }, SetOptions(merge: true));
      }

      // Verification email bhejo — sirf record ke liye, ab login isko
      // require nahi karta (signInWithEmailPassword mein check hata diya
      // gaya hai).
      await credential.user!.sendEmailVerification();

      // Signup ke baad sign out — user login screen se khud login karega.
      // Ab koi verification/approval wait nahi, login turant kaam karega.
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