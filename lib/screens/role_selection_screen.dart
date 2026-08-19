import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _backToLogin() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
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

            // ── Main content ──
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: screenHeight * 0.05,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        // ✅ Cards capped at ~960px on desktop instead of
                        // stretching edge-to-edge with a lot of dead space;
                        // shrinks naturally to full width on mobile.
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ NEW — small brand mark (icon + wordmark)
                            // above the status badge, so this screen reads
                            // as part of the same product as Login/Signup
                            // instead of a disconnected "step 3" screen.
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFEF5350),
                                        Color(0xFFB71C1C)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(Icons.water_drop_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'BloodConnect',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFB71C1C)
                                        .withOpacity(0.6)),
                                borderRadius: BorderRadius.circular(30),
                                color: const Color(0xFFB71C1C)
                                    .withOpacity(0.08),
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

                            SizedBox(height: screenHeight * 0.035),

                            // ✅ Action-first heading — covers both donor
                            // and receiver naturally, instead of "How will
                            // you help?" which read oddly for someone who
                            // just needs blood, not to give it.
                            const Text(
                              'How can we help\nyou today?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -1,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Choose an option to continue.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.045),

                            // Donor Card
                            _RoleCard(
                              icon: Icons.volunteer_activism_rounded,
                              badge: 'SAVE A LIFE',
                              title: 'Donate Blood',
                              description:
                              'Register as a donor and help someone in need.',
                              ctaLabel: 'Continue as Donor',
                              accentColor: const Color(0xFFEF5350),
                              glowColor: const Color(0xFFB71C1C),
                              isLoading:
                              _isLoading && _selectedRole == 'donor',
                              onTap: () => _handleRoleSelection('donor'),
                            ),

                            const SizedBox(height: 16),

                            // Receiver Card
                            _RoleCard(
                              icon: Icons.local_hospital_rounded,
                              badge: 'FIND A DONOR',
                              title: 'Request Blood',
                              description:
                              'Find compatible blood donors near you.',
                              ctaLabel: 'Continue as Receiver',
                              accentColor: const Color(0xFF42A5F5),
                              glowColor: const Color(0xFF1565C0),
                              isLoading:
                              _isLoading && _selectedRole == 'receiver',
                              onTap: () => _handleRoleSelection('receiver'),
                            ),

                            SizedBox(height: screenHeight * 0.04),

                            // ✅ Back-to-login moved to the bottom as a
                            // quiet closing line, outlined-button style,
                            // instead of competing with the heading at
                            // the top of the screen.
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _backToLogin,
                                icon: Icon(Icons.arrow_back_rounded,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.55)),
                                label: Text(
                                  'Already registered?  Back to Login',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.white.withOpacity(0.12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
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

// ─── Role Card ────────────────────────────────────────────────────────────
// ✅ Redesigned per spec: fixed compact height (~168px, no more sprawling
// empty space), left-aligned icon + copy, an explicit CTA pill with label
// text (not just a bare arrow circle) on the right, and a hover lift on
// desktop/web (translateY + border/shadow intensify) in addition to the
// existing tap-press feedback.
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String badge;
  final String title;
  final String description;
  final String ctaLabel;
  final Color accentColor;
  final Color glowColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
    required this.ctaLabel,
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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = _pressed || _hovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
              0, _hovering && !_pressed ? -4 : 0, 0),
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF13131A),
            border: Border.all(
              color: active
                  ? widget.accentColor.withOpacity(0.55)
                  : Colors.white.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(active ? 0.28 : 0.1),
                blurRadius: active ? 28 : 14,
                offset: Offset(0, active ? 12 : 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                child: Icon(widget.icon, color: widget.accentColor, size: 26),
              ),

              const SizedBox(width: 18),

              // Copy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.badge,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // CTA — explicit label + arrow, not just a bare icon circle
              widget.isLoading
                  ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.accentColor,
                ),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(active ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.ctaLabel,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        color: widget.accentColor, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grid background painter ───────────────────────────────────────────
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