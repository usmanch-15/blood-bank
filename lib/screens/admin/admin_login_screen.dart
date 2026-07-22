import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'web/admin_web_dashboard.dart';


class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> loginAdmin() async {
    setState(() => loading = true);

    try {
      String email = emailController.text.trim();
      String pass = passwordController.text.trim();

      // 🔐 FIREBASE LOGIN FIRST — we can't check Firestore role before we
      // know who the user is.
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      User? user = userCredential.user;

      if (user == null) throw Exception("Login failed");

      // 📧 EMAIL VERIFICATION CHECK (OTP LINK)
      if (!user.emailVerified) {
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification link sent to email"),
          ),
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      // ✅ FIX (Issue #8): admin access is no longer granted by a hardcoded
      // email list — it's checked against this user's actual role +
      // approval status stored in Firestore. Only an existing admin can
      // set another user's role to "admin".
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = userDoc.data()?['role'];
      final status = userDoc.data()?['status'];

      if (role != 'admin' || status != 'approved') {
        await FirebaseAuth.instance.signOut();
        throw Exception("❌ Not authorized admin");
      }

      // ✅ SUCCESS → DASHBOARD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminWebDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Admin Login",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Admin Email"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : loginAdmin,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login Admin"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}