import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../services/settings_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/validators.dart';

/// ✅ NEW — Change Email screen.
/// Sends a confirmation link to the new address; the email only actually
/// changes once the user clicks that link (Firebase requires this — see
/// the comment on SettingsService.changeEmail for why).
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _settingsService = SettingsService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _sent = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _settingsService.changeEmail(
        currentPassword: _passwordController.text,
        newEmail: _newEmailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = AppLocalizations.of(context).passwordIncorrect;
          break;
        case 'email-already-in-use':
          message = AppLocalizations.of(context).emailAlreadyUsed;
          break;
        case 'invalid-email':
          message = AppLocalizations.of(context).enterValidEmail;
          break;
        case 'requires-recent-login':
          message = AppLocalizations.of(context).reauthenticateRequired;
          break;
        default:
          message = e.message ?? AppLocalizations.of(context).operationFailed;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).changeEmail),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body:
          _sent
              ? _buildConfirmationSent(context)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).currentEmail(currentEmail),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _newEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context).newEmailAddress,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final formatError = AppValidators.validateEmail(v);
                          if (formatError != null) {
                            return v == null || v.trim().isEmpty
                                ? AppLocalizations.of(context).enterNewEmail
                                : AppLocalizations.of(context).enterValidEmail;
                          }
                          if (v?.trim().toLowerCase() ==
                              currentEmail.toLowerCase()) {
                            return AppLocalizations.of(
                              context,
                            ).emailAlreadyCurrent;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context).currentPassword,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty)
                                    ? AppLocalizations.of(
                                      context,
                                    ).enterCurrentPassword
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).emailChangeSecurityNote,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    AppLocalizations.of(
                                      context,
                                    ).sendConfirmationLink,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildConfirmationSent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).confirmationLinkSent,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(
                context,
              ).emailChangeConfirmation(_newEmailController.text.trim()),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).done),
            ),
          ],
        ),
      ),
    );
  }
}
