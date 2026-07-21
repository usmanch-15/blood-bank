import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';

/// Standalone phone-number OTP verification screen.
/// Firebase Console mein Authentication -> Sign-in method -> Phone
/// provider enable hona zaroori hai, warna sendOtp() error dega.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber; // format: +923001234567

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _authService.sendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _codeSent = true;
          _isLoading = false;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _error = err;
          _isLoading = false;
        });
      },
      onAutoVerified: (credential) async {
        // Kuch Android devices par SMS khud-ba-khud detect ho jata hai
        if (!mounted) return;
        Navigator.pop(context, true);
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _codeController.text.trim().length < 6) {
      setState(() => _error = 'Poora 6-digit code darj karein.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.verifyOtpAndLink(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.sms_outlined, size: 56, color: AppColors.primaryRed),
            const SizedBox(height: 16),
            Text(
              _codeSent
                  ? 'Enter the 6-digit code sent to ${widget.phoneNumber}'
                  : 'Sending code to ${widget.phoneNumber}...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '000000',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Verify',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : _sendCode,
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}