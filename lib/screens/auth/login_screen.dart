import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/push_navigation_service.dart';
import '../../widgets/dashboard_components.dart'; // ✅ light-touch polish
import '../../utils/account_policy.dart';
import '../../utils/input_formatters.dart';
import '../../utils/validators.dart';
import 'signup_screen.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // ✅ FIX (Issue #8): admin access used to be granted purely by
      // matching a hardcoded email list (AdminConfig.adminEmails). If that
      // list ever leaked, anyone using one of those emails became admin.
      // Authorization comes from the protected Firestore role, never from a
      // client-side email or password allowlist.
      final userData = await _authService.getUserData(userCredential.user!.uid);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AccountPolicy.route(userData!),
        (route) => false,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => PushNavigationService.instance.sessionLanded(),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;

      if (message == 'email-not-verified') {
        _showStatusDialog(
          icon: Icons.mark_email_unread_rounded,
          iconColor: const Color(0xFF42A5F5),
          title: AppLocalizations.of(context).verifyEmail,
          message: AppLocalizations.of(context).verifyEmailMessage,
        );
      } else if (message == 'rejected') {
        _showStatusDialog(
          icon: Icons.cancel_rounded,
          iconColor: const Color(0xFFEF5350),
          title: AppLocalizations.of(context).accountRejected,
          message: AppLocalizations.of(context).accountRejectedMessage,
        );
      } else {
        _showErrorSnack(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _showStatusDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder:
          (ctx) => Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, size: 36, color: iconColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).understood,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Connect')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Icon(
                              Icons.bloodtype_outlined,
                              size: 40,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l.welcomeBack,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dashboardText(
                              context,
                              'Sign in to manage your requests and donations.',
                              'اپنی درخواستیں اور عطیات دیکھنے کے لیے سائن ان کریں۔',
                            ),
                            style: TextStyle(color: c.onSurfaceVariant),
                          ),
                          const SizedBox(height: 28),
                          _buildField(
                            controller: _emailController,
                            hint: l.emailHint,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: AppInputFormatters.email,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            controller: _passwordController,
                            hint: dashboardText(context, 'Password', 'پاس ورڈ'),
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _handleLogin(),
                            suffix: IconButton(
                              tooltip: dashboardText(
                                context,
                                'Show or hide password',
                                'پاس ورڈ دکھائیں یا چھپائیں',
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            validator: AppValidators.validateLoginPassword,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _showForgotPassword,
                              child: Text(l.resetPassword),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLoginButton(),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    ),
                            child: Text(
                              dashboardText(
                                context,
                                'Create an account',
                                'اکاؤنٹ بنائیں',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction, // ✅ NEW
    Iterable<String>? autofillHints, // ✅ NEW
    void Function(String)? onSubmitted, // ✅ NEW
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildLoginButton() => FilledButton(
    onPressed: _isLoading ? null : _handleLogin,
    child:
        _isLoading
            ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : Text(dashboardText(context, 'Login', 'لاگ ان')),
  );

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    final emailFieldKey = GlobalKey<FormFieldState<String>>();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (ctx) => Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset_outlined,
                      color: Color(0xFFEF5350),
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).resetPassword,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context).resetPasswordHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: emailFieldKey,
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: AppInputFormatters.email,
                      validator: AppValidators.validateEmail,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).emailHint,
                        hintStyle: const TextStyle(color: Color(0xFF3D3D3D)),
                        filled: true,
                        fillColor: const Color(0xFF111111),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFB71C1C),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              AppLocalizations.of(context).cancelAction,
                              style: TextStyle(color: Color(0xFF757575)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (!emailFieldKey.currentState!.validate()) {
                                return;
                              }
                              Navigator.pop(ctx);
                              try {
                                await _authService.resetPassword(
                                  emailCtrl.text.trim(),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).resetLinkSent,
                                      ),
                                      backgroundColor: Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) _showErrorSnack(e.toString());
                              }
                            },
                            child: Text(
                              AppLocalizations.of(context).sendLink,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
