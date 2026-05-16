import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo scale + fade
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Text fade + slide
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  // Tagline fade
  late AnimationController _taglineController;
  late Animation<double> _taglineOpacity;

  // Glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  // Progress bar
  late AnimationController _progressController;

  // Rotating ring
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // ── Logo ────────────────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // ── App Name ────────────────────────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // ── Tagline ─────────────────────────────────────────────
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // ── Glow Pulse ──────────────────────────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 60, end: 110).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // ── Progress bar ─────────────────────────────────────────
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // ── Rotating ring ────────────────────────────────────────
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Sequence
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();

    // Navigate after 3 seconds total
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/sensors');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A2E0A),
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF1A4A1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Background circuit dots ──────────────────────────────
            _buildCircuitBackground(size),

            // ── Content ─────────────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo with glow + ring ──────────────────────────
                _buildLogoSection(),

                const SizedBox(height: 36),

                // ── App Name ───────────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        // AgroIntelX text
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Agro',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Intel',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF76FF03),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'X',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Divider line
                        Container(
                          width: 180,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF76FF03),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tagline ────────────────────────────────────────
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'Smart Farming • IoT Intelligence • AI Insights',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // Feature chips
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildChip('🌡️ Sensors'),
                      _buildChip('🌤 Weather'),
                      _buildChip('🌾 Market'),
                      _buildChip('🤖 AI'),
                    ],
                  ),
                ),
              ],
            ),

            // ── Bottom progress bar ──────────────────────────────────
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF76FF03),
                              ),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _progressController.value < 0.4
                                ? 'Initializing sensors...'
                                : _progressController.value < 0.75
                                ? 'Loading AI models...'
                                : 'Ready!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Version tag ──────────────────────────────────────────
            Positioned(
              bottom: 24,
              child: Text(
                'v1.0.0 • Powered by Gemini AI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _glowController,
        _ringController,
      ]),
      builder: (_, __) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: _glowRadius.value * 2,
                height: _glowRadius.value * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF76FF03).withOpacity(0.18),
                      const Color(0xFF1B5E20).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Rotating dashed ring
              Transform.rotate(
                angle: _ringController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: _DashedRingPainter(
                    color: const Color(0xFF76FF03).withOpacity(0.4),
                    strokeWidth: 2,
                    dashCount: 16,
                  ),
                ),
              ),

              // Counter-rotating ring (smaller)
              Transform.rotate(
                angle: -_ringController.value * 2 * math.pi * 0.6,
                child: CustomPaint(
                  size: const Size(145, 145),
                  painter: _DashedRingPainter(
                    color: Colors.white.withOpacity(0.2),
                    strokeWidth: 1.5,
                    dashCount: 10,
                  ),
                ),
              ),

              // Logo container
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF76FF03).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/images/agrointelx_logo.png',
                          fit: BoxFit.contain,
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
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCircuitBackground(Size size) {
    return Positioned.fill(
      child: CustomPaint(painter: _CircuitBackgroundPainter()),
    );
  }
}

// ─── Dashed Ring Painter ─────────────────────────────────────────────────────

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  const _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final step = (2 * math.pi) / dashCount;
    final dashAngle = step * 0.5;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) =>
      old.color != color || old.dashCount != dashCount;
}

// ─── Circuit Background Painter ──────────────────────────────────────────────

class _CircuitBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.fill;

    final rng = math.Random(42);

    // Draw subtle circuit lines
    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = 30 + rng.nextDouble() * 60;
      final horizontal = rng.nextBool();

      canvas.drawLine(
        Offset(x, y),
        horizontal ? Offset(x + len, y) : Offset(x, y + len),
        paint,
      );

      // Corner dot
      canvas.drawCircle(
        horizontal ? Offset(x + len, y) : Offset(x, y + len),
        2.5,
        dotPaint,
      );
    }

    // Scatter dots
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        1.5,
        Paint()..color = const Color(0xFF76FF03).withOpacity(0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
