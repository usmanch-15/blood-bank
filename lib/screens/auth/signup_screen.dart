import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart'; // ✅ light-touch polish
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

/// ✅ NEW — auto-inserts the CNIC dashes as the user types
/// (12345-1234567-1), same UX pattern as bank/telco apps use for CNIC.
class _CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits =
    newValue.text.replaceAll(RegExp(r'[^0-9]'), '').substring(
        0, newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length > 13
        ? 13
        : newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 4 || i == 11) {
        if (i != digits.length - 1) buffer.write('-');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController(); // ✅ NEW
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedBloodGroup;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 100), () => _slideCtrl.forward());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose(); // ✅ NEW
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.signupWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: 'donor',
        phoneNumber: _phoneController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        cnic: _cnicController.text.trim(), // ✅ NEW
      );
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(fontSize: 13))),
            ]),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.lg),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB300).withOpacity(0.1),
                border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.3),
                    width: 2),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 38, color: Color(0xFFFFB300)),
            ),
            const SizedBox(height: 22),
            const Text(
              'Registration Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your account is pending admin approval.\n\nYou will be able to login once your account is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  height: 1.6),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go to Login',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -60,
            left: -60,
            child: _glowBlob(220, const Color(0xFFB71C1C), 0.25),
          ),
          Positioned(
            bottom: 0,
            right: -80,
            child: _glowBlob(200, const Color(0xFF7B0000), 0.18),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(children: [
                      _backButton(),
                      const Spacer(),
                      // Step indicator dots
                      Row(children: [
                        _dot(true),
                        const SizedBox(width: 5),
                        _dot(false),
                      ]),
                    ]),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),

                            // Header
                            Row(children: [
                              _buildMiniLogo(),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Join the lifesaving community',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF616161),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                            const SizedBox(height: 32),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                                children: [
                                  // Full Name
                                  _buildLabel('Full Name'),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _nameController,
                                    hint: 'Muhammad Ali',
                                    icon: Icons.person_outline,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Name required';
                                      if (v.length < 3)
                                        return 'Min 3 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Email
                                  _buildLabel('Email Address'),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _emailController,
                                    hint: 'your@email.com',
                                    icon: Icons.email_outlined,
                                    keyboardType:
                                    TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Email required';
                                      if (!v.contains('@') ||
                                          !v.contains('.'))
                                        return 'Enter valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Phone
                                  _buildLabel('Phone Number'),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _phoneController,
                                    hint: '03XX-XXXXXXX',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Phone required';
                                      if (v.length < 11)
                                        return 'Enter valid number';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // ✅ NEW — CNIC (National ID)
                                  _buildLabel('CNIC (National ID)'),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _cnicController,
                                    hint: '12345-1234567-1',
                                    icon: Icons.badge_outlined,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [_CnicInputFormatter()],
                                    validator: AppValidators.validateCnic,
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(left: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock_outline,
                                            size: 13,
                                            color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Used only to verify identity — kept private.',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Blood Group
                                  _buildLabel('Blood Group'),
                                  const SizedBox(height: 8),
                                  _buildDropdown(),
                                  const SizedBox(height: 18),

                                  // Password
                                  _buildLabel('Password'),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _passwordController,
                                    hint: 'Min 6 characters',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    suffix: GestureDetector(
                                      onTap: () => setState(() =>
                                      _obscurePassword =
                                      !_obscurePassword),
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF616161),
                                        size: 20,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password required';
                                      if (v.length < 6)
                                        return 'Min 6 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Confirm Password
                                  _buildLabel('Confirm Password'),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _confirmPasswordController,
                                    hint: 'Re-enter password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    suffix: GestureDetector(
                                      onTap: () => setState(() =>
                                      _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                                      child: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF616161),
                                        size: 20,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Confirm your password';
                                      if (v != _passwordController.text)
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),

                                  // Info strip
                                  _buildInfoStrip(),
                                  const SizedBox(height: 24),

                                  // Submit button
                                  _buildSignUpButton(),
                                  const SizedBox(height: 24),

                                  // Already have account
                                  // Centered on wide screens; on very narrow
                                  // phones "Sign In" wraps to the next line
                                  // instead of overflowing the row.
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text('Already have an account? ',
                                          style: TextStyle(
                                              color: Color(0xFF616161),
                                              fontSize: 14)),
                                      GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Sign In',
                                            style: TextStyle(
                                                color: Color(0xFFEF5350),
                                                fontSize: 14,
                                                fontWeight:
                                                FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white70, size: 16),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFB71C1C)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildMiniLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD32F2F), Color(0xFF7B0000)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB71C1C).withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.bloodtype_rounded,
          color: Colors.white, size: 26),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // ✅ NEW
    TextInputAction? textInputAction, // ✅ NEW
    Iterable<String>? autofillHints, // ✅ NEW
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(color: Color(0xFF3D3D3D), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        prefixIcon:
        Icon(icon, color: const Color(0xFF616161), size: 20),
        suffixIcon: suffix != null
            ? Padding(
          padding: const EdgeInsets.only(right: 14),
          child: suffix,
        )
            : null,
        suffixIconConstraints:
        const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFB71C1C), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFFEF5350))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFEF5350), width: 1.5)),
        errorStyle: const TextStyle(
            color: Color(0xFFEF5350), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF616161)),
      decoration: InputDecoration(
        hintText: 'Select blood group',
        hintStyle:
        const TextStyle(color: Color(0xFF3D3D3D), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        prefixIcon: const Icon(Icons.bloodtype_outlined,
            color: Color(0xFF616161), size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFB71C1C), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFFEF5350))),
        errorStyle: const TextStyle(
            color: Color(0xFFEF5350), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
      ),
      items: AppConstants.bloodGroups
          .map((group) => DropdownMenuItem(
        value: group,
        child: Text(group,
            style: const TextStyle(color: Colors.white)),
      ))
          .toList(),
      onChanged: (value) =>
          setState(() => _selectedBloodGroup = value),
      validator: (v) =>
      (v == null || v.isEmpty) ? 'Select blood group' : null,
    );
  }

  Widget _buildInfoStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFB71C1C).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline,
              color: Color(0xFFEF5350), size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your account will be reviewed by admin before activation.',
              style: TextStyle(
                  color: Color(0xFF9E9E9E), fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isLoading
                ? const LinearGradient(
                colors: [Color(0xFF5D0000), Color(0xFF4A0000)])
                : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD32F2F), Color(0xFF8B0000)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isLoading
                ? []
                : [
              BoxShadow(
                color:
                const Color(0xFFB71C1C).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 2))
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite,
                    color: Colors.white70, size: 18),
                SizedBox(width: 10),
                Text('Create Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}