import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/settings_service.dart';
import '../../utils/validators.dart';
import '../auth/otp_verification_screen.dart';

class PhoneSettingsScreen extends StatefulWidget {
  const PhoneSettingsScreen({super.key});
  @override
  State<PhoneSettingsScreen> createState() => _PhoneSettingsScreenState();
}

class _PhoneSettingsScreenState extends State<PhoneSettingsScreen> {
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final number = await SettingsService().getPhoneOnce();
      if (mounted) _phone.text = number ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify / Change Phone')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            FirebaseAuth.instance.currentUser?.phoneNumber == null
                ? 'Your phone is not verified.'
                : 'Verified phone: ${FirebaseAuth.instance.currentUser!.phoneNumber}',
          ),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: AppValidators.validatePhone,
            decoration: const InputDecoration(labelText: 'Mobile number'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed:
                _busy
                    ? null
                    : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() => _busy = true);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OtpVerificationScreen(
                                phoneNumber: AppValidators.normalizePhone(
                                  _phone.text,
                                ),
                              ),
                        ),
                      );
                      if (mounted) {
                        setState(() => _busy = false);
                        await _load();
                      }
                    },
            child: const Text('Send verification code'),
          ),
        ],
      ),
    ),
  );
}
