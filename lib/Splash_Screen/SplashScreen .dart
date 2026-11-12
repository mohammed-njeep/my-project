// ignore: file_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_project/Login/LoginScreen.dart';

class AdvancedSplashScreen extends StatefulWidget {
  const AdvancedSplashScreen({super.key});

  @override
  State<AdvancedSplashScreen> createState() => _AdvancedSplashScreenState();
}

class _AdvancedSplashScreenState extends State<AdvancedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _navigateToNext();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 4000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: BackgroundWavePainter(_waveController.value),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00E5FF), Color(0xFF0052D4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 122,
                          height: 122,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0A192F),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            size: 65,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                    )
                    .then()
                    .shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withOpacity(0.5),
                    ),
                const SizedBox(height: 35),
                const Text(
                      'نظام إحصاء السكان (PDMS)',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 800.ms)
                    .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: const Text(
                        'إدارة وتتبع البيانات الميدانية دون اتصال',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8892B0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 800.ms)
                    .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Color(0xFF172A45),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'جاري تهيئة قاعدة البيانات المحلية...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

class BackgroundWavePainter extends CustomPainter {
  final double animationValue;
  BackgroundWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = const Color(0xFF0052D4).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final path1 = Path();
    final path2 = Path();
    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);
    for (double i = 0; i <= size.width; i++) {
      double y1 =
          math.sin(
                (i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi),
              ) *
              15 +
          size.height * 0.85;
      path1.lineTo(i, y1);
      double y2 =
          math.cos(
                (i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi),
              ) *
              20 +
          size.height * 0.88;
      path2.lineTo(i, y2);
    }
    path1.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
