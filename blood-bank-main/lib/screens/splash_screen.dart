import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 // ✅ Directly to Login Screen
import '../constants/app_colors.dart';
import 'auth/login_screen.dart';

/// Premium Blood Bank Splash Screen - Modern 3D Effects
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _particleAnimation;

  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF8B0000),
    ));

    // Initialize particles
    _initializeParticles();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Multiple animations - FIXED TweenSequence
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    // FIXED: Correct TweenSequence with proper weights and intervals
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFF8B0000),
      end: const Color(0xFFFF0000),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations with safe value checking
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.repeat(reverse: true);
      }
    });

    // Start animation safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });

    // ✅ FIXED: Navigate directly to Login Screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    });
  }

  void _initializeParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 2 + _random.nextDouble() * 6,
        opacity: 0.1 + _random.nextDouble() * 0.4,
      ));
    }
  }

  void _updateParticles() {
    for (final particle in _particles) {
      particle.y -= 0.005 * particle.speed;
      if (particle.y < -0.1) {
        particle.y = 1.1;
        particle.x = _random.nextDouble();
      }
      particle.x += sin(particle.y * pi) * 0.003;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _animationController,
          _fadeAnimation,
          _scaleAnimation,
          _rotateAnimation,
          _floatAnimation,
          _colorAnimation,
          _particleAnimation,
        ]),
        builder: (context, child) {
          _updateParticles();

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  _colorAnimation.value ?? const Color(0xFF8B0000),
                  const Color(0xFF8B0000),
                  const Color(0xFF5A0000),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                for (final particle in _particles)
                  Positioned(
                    left: particle.x * screenSize.width,
                    top: particle.y * screenSize.height,
                    child: Opacity(
                      opacity: particle.opacity,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          sin((_particleAnimation.value + particle.x) * pi * 2) *
                              10,
                        ),
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.5),
                                blurRadius: particle.size,
                                spreadRadius: particle.size / 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Glowing orb effect
                Positioned(
                  top: -screenSize.height * 0.3,
                  right: -screenSize.width * 0.3,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Container(
                      width: screenSize.width * 0.8,
                      height: screenSize.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.3),
                            Colors.red.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 3D Heart with floating animation
                      Transform.translate(
                        offset: Offset(0, -_floatAnimation.value),
                        child: Transform.scale(
                          scale: _scaleAnimation.value.clamp(0.0, 2.0), // Safe clamp
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.1, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // 3D Heart container
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.red[50]!,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red[900]!.withOpacity(0.6),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                      offset: const Offset(0, 20),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: -10,
                                      offset: const Offset(-10, -10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF8B0000),
                                          const Color(0xFFFF0000),
                                          const Color(0xFFFF4444),
                                        ],
                                        stops: const [0.2, 0.5, 0.8],
                                      ).createShader(bounds);
                                    },
                                    child: const Icon(
                                      Icons.favorite,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Animated blood drops around heart
                              ...List.generate(8, (index) {
                                final angle = (index / 8) * 2 * pi;
                                final radius = 100;
                                final animValue = _animationController.value % 1.0;
                                final x = radius * cos(angle + animValue * pi / 2);
                                final y = radius * sin(angle + animValue * pi / 2);

                                return Positioned(
                                  left: 80 + x,
                                  top: 80 + y,
                                  child: Transform.scale(
                                    scale: (0.5 + 0.5 * sin((animValue + index / 8) * pi * 2))
                                        .clamp(0.0, 1.5),
                                    child: Container(
                                      width: 16,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFF0000),
                                            const Color(0xFF8B0000),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(8),
                                          bottom: Radius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // App title with modern typography
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Main title with gradient text
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.red[100]!,
                                  ],
                                  stops: const [0.3, 1.0],
                                ).createShader(bounds);
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'BLOOD HERO',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    height: 1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.red[900]!.withOpacity(0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle with animated underline
                            SizedBox(
                              height: 20,
                              child: Stack(
                                children: [
                                  Text(
                                    'LIFE SAVING NETWORK',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 5,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      width: 200 * (_animationController.value * 1.5 % 1),
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.transparent,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Modern loading indicator
                      SizedBox(
                        width: 200,
                        child: Column(
                          children: [
                            // Progress bar
                            Stack(
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  height: 4,
                                  width: 200 * (_animationController.value % 1.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.red[100]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Loading text with dots animation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'INITIALIZING SYSTEM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(3, (index) {
                                  final dotOpacity = (_animationController.value * 3 % 1) > index / 3
                                      ? 1.0
                                      : 0.3;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Opacity(
                                      opacity: dotOpacity,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Stats counters
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 30,
                          runSpacing: 12,
                          children: [
                            _buildStatCounter('LIVES SAVED', '1,234+'),
                            _buildStatCounter('DONORS', '5,678+'),
                            _buildStatCounter('ACTIVE', '24/7'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom wave effect
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      sin((_animationController.value % 1.0) * pi * 2) * 10,
                    ),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _WavePainter(
                          animationValue: _animationController.value % 1.0,
                        ),
                        size: Size(screenSize.width, 80),
                      ),
                    ),
                  ),
                ),

                // Top right premium badge
                Positioned(
                  top: 60,
                  right: 30,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.rotate(
                      angle: pi / 4,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.redAccent,
                              Colors.red[900]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -pi / 4,
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCounter(String title, String value) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                Colors.red[100]!,
              ],
            ).createShader(bounds);
          },
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Particle class for background animation
class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

/// Wave painter for bottom animation
class _WavePainter extends CustomPainter {
  final double animationValue;

  _WavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i++) {
      final x = i;
      final y = size.height * 0.5 +
          sin((i / size.width * 4 * pi) + (animationValue * 2 * pi)) * 15;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}