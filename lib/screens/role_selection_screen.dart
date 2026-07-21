import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'donor/donor_dashboard_screen.dart';
import 'receiver/receiver_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  bool _isLoading = false;
  String? _selectedRole;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRoleSelection(String role) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _selectedRole = role;
    });

    try {
      User? user = _authService.currentUser;
      if (user != null) {
        // ✅ FIX: 'role' sirf current UI mode set karta hai (kaunsa dashboard
        // khulega). isDonor / isReceiver capability flags additive hain —
        // ek dafa true hone ke baad reset nahi hotay, is liye same account
        // donor aur receiver dono ban sakta hai, aur role switch karne se
        // donor search results se gayab nahi hota.
        await _authService.updateUserData(user.uid, {
          'role': role,
          if (role == 'donor') 'isDonor': true,
          if (role == 'receiver') 'isReceiver': true,
        });

        // ✅ FIX: pehle NotificationService.init() kahin bhi call hi nahi
        // hota tha — is liye fcmToken kabhi save hi nahi hota tha aur push
        // notifications kabhi device par pohanch hi nahi sakti thi.
        await NotificationService().init();
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'donor'
              ? const DonorDashboardScreen()
              : const ReceiverDashboardScreen(),
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Stack(
          children: [
            // ── Background blobs ──
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB71C1C).withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1565C0).withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Grid lines ──
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              painter: _GridPainter(),
            ),

            // ── Main content — SingleChildScrollView se overflow fix ──
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(         // ← overflow fix
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: screenHeight * 0.04,   // responsive vertical padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                const Color(0xFFB71C1C).withOpacity(0.6)),
                            borderRadius: BorderRadius.circular(30),
                            color:
                            const Color(0xFFB71C1C).withOpacity(0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEF5350),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Blood Connect',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Back to Login button ──
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () async {
                              await _authService.signOut();
                              if (!mounted) return;
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_ios_rounded,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Heading
                        const Text(
                          'How will\nyou help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Choose your role to get started.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.05),

                        // Donor Card
                        _RoleCard(
                          title: 'Donor',
                          subtitle: 'Give blood,\nsave a life today',
                          tag: 'DONATE',
                          icon: Icons.volunteer_activism_rounded,
                          accentColor: const Color(0xFFEF5350),
                          glowColor: const Color(0xFFB71C1C),
                          isLoading:
                          _isLoading && _selectedRole == 'donor',
                          onTap: () => _handleRoleSelection('donor'),
                        ),

                        const SizedBox(height: 16),

                        // Receiver Card
                        _RoleCard(
                          title: 'Receiver',
                          subtitle: 'Find donors\nnear you fast',
                          tag: 'REQUEST',
                          icon: Icons.local_hospital_rounded,
                          accentColor: const Color(0xFF42A5F5),
                          glowColor: const Color(0xFF1565C0),
                          isLoading:
                          _isLoading && _selectedRole == 'receiver',
                          onTap: () => _handleRoleSelection('receiver'),
                        ),

                        // Extra bottom padding taake nav bar se overlap na ho
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Card ────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color accentColor;
  final Color glowColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.accentColor,
    required this.glowColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF13131A),
            border: Border.all(
              color: _pressed
                  ? widget.accentColor.withOpacity(0.6)
                  : Colors.white.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor
                    .withOpacity(_pressed ? 0.3 : 0.12),
                blurRadius: _pressed ? 30 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor.withOpacity(0.25),
                      widget.glowColor.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(widget.icon,
                    color: widget.accentColor, size: 32),
              ),

              const SizedBox(width: 20),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.tag,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow / loader
              widget.isLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.accentColor,
                ),
              )
                  : Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.accentColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grid background painter ──────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.8;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}