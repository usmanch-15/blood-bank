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

      // Turant logout — admin approve kare tab tak wait
      await _auth.signOut();

      return credential;
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