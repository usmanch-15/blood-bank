import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// match your actual filename
import 'admin_config.dart';


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

      // ❌ BLOCK NON ADMIN EMAILS
      if (!AdminConfig.adminEmails.contains(email)) {
        throw Exception("❌ Not authorized admin");
      }

      // 🔐 FIREBASE LOGIN
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

      // ✅ SUCCESS → DASHBOARD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
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