import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin_config.dart';

class AdminWebLogin extends StatefulWidget {
  const AdminWebLogin({Key? key}) : super(key: key);

  @override
  State<AdminWebLogin> createState() => _AdminWebLoginState();
}

class _AdminWebLoginState extends State<AdminWebLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // ❌ Admin whitelist check
      if (!AdminConfig.adminEmails.contains(email)) {
        _showError('❌ Yeh email admin nahi hai.');
        setState(() => _isLoading = false);
        return;
      }

      // 🔐 Firebase login
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        _showError('Login fail ho gaya. Dobara try karo.');
        setState(() => _isLoading = false);
        return;
      }

      // 📧 Email verification check
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        _showError('📧 Verification email bhej di — pehle verify karo.');
        await FirebaseAuth.instance.signOut();
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Admin dashboard open karo
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login fail ho gaya.';
      if (e.code == 'user-not-found') msg = 'Yeh email registered nahi hai.';
      if (e.code == 'wrong-password') msg = 'Password galat hai.';
      if (e.code == 'invalid-credential') msg = 'Email ya password galat hai.';
      if (e.code == 'too-many-requests') msg = 'Zyada attempts. Thodi der baad try karo.';
      _showError(msg);
    } catch (e) {
      _showError(e.toString());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.white,
              Colors.red.shade50,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bloodtype,
                          size: 60,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'BloodLink Admin Portal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to manage your blood donation platform',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Admin Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email daalo';
                          }
                          if (!value.contains('@')) {
                            return 'Valid email daalo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password daalo';
                          }
                          if (value.length < 6) {
                            return 'Password kam se kam 6 characters ka ho';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          String email = _emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            _showError('Pehle email field mein email daalo');
                            return;
                          }
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: email);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email bhej di ✅'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}