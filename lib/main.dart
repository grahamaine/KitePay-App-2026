import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:turnkey_sdk_flutter/turnkey_sdk_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/agent_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand tokens
// ─────────────────────────────────────────────────────────────────────────────
class KiteColors {
  KiteColors._();

  // Dark navy base
  static const Color navy900 = Color(0xFF050D1A);
  static const Color navy800 = Color(0xFF0A1628);
  static const Color navy700 = Color(0xFF0F2040);
  static const Color navy600 = Color(0xFF142B58);

  // Electric cyan accent
  static const Color cyan400 = Color(0xFF00E5FF);
  static const Color cyan300 = Color(0xFF4DFBFF);
  static const Color cyan500 = Color(0xFF00B8D4);

  // Warm gold — secondary accent for trust / finance feel
  static const Color gold400 = Color(0xFFFFCA28);
  static const Color gold300 = Color(0xFFFFE082);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF5F7FA);
  static const Color grey400 = Color(0xFF9AA5B4);
  static const Color grey600 = Color(0xFF627D98);

  // Semantic
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
}

// ─────────────────────────────────────────────────────────────────────────────
// App entry
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive edge-to-edge display
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: KiteColors.navy900,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TurnkeyProvider(
            config: TurnkeyConfig(
              apiBaseUrl: 'https://api.turnkey.com',
              organizationId: const String.fromEnvironment('TURNKEY_ORG_ID'),
              appScheme: 'kitepay',
              onSessionCreated: (_) => debugPrint('✅ Session created'),
              onSessionSelected: (_) => debugPrint('🔄 Session selected'),
              onSessionExpired: (_) => debugPrint('⚠️  Session expired'),
              onSessionCleared: (_) => debugPrint('🗑  Session cleared'),
              onInitialized: (err) =>
                  debugPrint(err?.toString() ?? '🚀 Turnkey initialized'),
            ),
          ),
        ),
        ChangeNotifierProxyProvider<TurnkeyProvider, KiteAgentService>(
          create: (ctx) => KiteAgentService(ctx.read<TurnkeyProvider>()),
          update: (_, turnkey, prev) => prev ?? KiteAgentService(turnkey),
        ),
      ],
      child: const KitePayApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root app
// ─────────────────────────────────────────────────────────────────────────────
class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitePay',
      debugShowCheckedModeBanner: false,

      // ── Dark theme (primary) ──────────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: KiteColors.cyan400,
          onPrimary: KiteColors.navy900,
          secondary: KiteColors.gold400,
          onSecondary: KiteColors.navy900,
          surface: KiteColors.navy800,
          onSurface: KiteColors.white,
          error: KiteColors.error,
        ),
        scaffoldBackgroundColor: KiteColors.navy900,
        cardColor: KiteColors.navy800,
        dividerColor: KiteColors.navy700,

        // Typography — use the system default but override key styles
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            color: KiteColors.white,
            height: 1.05,
          ),
          displayMedium: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: KiteColors.white,
          ),
          displaySmall: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: KiteColors.white,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: KiteColors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: KiteColors.white,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: KiteColors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: KiteColors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: KiteColors.grey100,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: KiteColors.grey400,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: KiteColors.navy900,
          ),
        ),

        // FilledButton — cyan pill
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: KiteColors.cyan400,
            foregroundColor: KiteColors.navy900,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            elevation: 0,
          ),
        ),

        // OutlinedButton — ghost on navy
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: KiteColors.cyan400,
            side: const BorderSide(color: KiteColors.cyan400, width: 1.5),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KiteColors.cyan400,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KiteColors.navy700,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KiteColors.navy600, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KiteColors.cyan400, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KiteColors.error, width: 1.5),
          ),
          labelStyle: const TextStyle(color: KiteColors.grey400),
          hintStyle: const TextStyle(color: KiteColors.grey600),
          prefixIconColor: KiteColors.grey400,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: KiteColors.navy900,
          foregroundColor: KiteColors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KiteColors.white,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: KiteColors.white),
        ),

        // Card
        cardTheme: CardThemeData(
          color: KiteColors.navy800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: KiteColors.navy700, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: KiteColors.navy700,
          contentTextStyle: const TextStyle(color: KiteColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // Icon
        iconTheme: const IconThemeData(color: KiteColors.grey400),
      ),

      // ── Light theme (fallback) ────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: KiteColors.navy800,
          brightness: Brightness.light,
        ),
      ),

      themeMode: ThemeMode.dark, // lock to dark — brand identity

      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate — animated splash while checking session
// ─────────────────────────────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final turnkey = context.read<TurnkeyProvider>();
    await turnkey.ready;

    // Hold splash for at least 1.8 s so the animation completes
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    final session = await turnkey.getSession();
    if (!mounted) return;

    final destination =
        session != null ? const HomeScreen() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => destination,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated radial gradient background ──────────────────────────
          const _PulsingBackground(),

          // ── Grid lines (subtle fintech texture) ──────────────────────────
          CustomPaint(painter: _GridPainter()),

          // ── Center content ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const _KiteLogoMark(size: 100),
                  ),
                ),
                const SizedBox(height: 28),

                // Wordmark
                FadeTransition(
                  opacity: _logoFade,
                  child: const _KiteWordmark(),
                ),
                const SizedBox(height: 16),

                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Text(
                      'Fly further with every payment',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: KiteColors.grey400,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom loading indicator ──────────────────────────────────────
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      KiteColors.cyan400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo mark — geometric kite diamond with cyan glow
// ─────────────────────────────────────────────────────────────────────────────
class _KiteLogoMark extends StatelessWidget {
  final double size;
  const _KiteLogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KiteColors.navy800,
        border: Border.all(
            color: KiteColors.cyan400.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: KiteColors.cyan400.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: KiteColors.cyan400.withValues(alpha: 0.1),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.5, size * 0.5),
          painter: _KiteDiamondPainter(),
        ),
      ),
    );
  }
}

class _KiteDiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer diamond fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [KiteColors.cyan300, KiteColors.cyan500],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final diamond = Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width, cy * 1.1)
      ..lineTo(cx, size.height)
      ..lineTo(0, cy * 1.1)
      ..close();

    canvas.drawPath(diamond, fillPaint);

    // Inner accent line (kite cross)
    final linePaint = Paint()
      ..color = KiteColors.navy900.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), linePaint);
    canvas.drawLine(
        Offset(0, cy * 1.1), Offset(size.width, cy * 1.1), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Wordmark
// ─────────────────────────────────────────────────────────────────────────────
class _KiteWordmark extends StatelessWidget {
  const _KiteWordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [KiteColors.white, KiteColors.cyan300],
        stops: [0.5, 1.0],
      ).createShader(bounds),
      child: const Text(
        'KitePay',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          color: Colors.white, // masked by shader
          letterSpacing: -1.5,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated radial glow background
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingBackground extends StatefulWidget {
  const _PulsingBackground();

  @override
  State<_PulsingBackground> createState() => _PulsingBackgroundState();
}

class _PulsingBackgroundState extends State<_PulsingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => CustomPaint(
        painter: _GlowPainter(_pulse.value),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double intensity;
  _GlowPainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    // Primary cyan glow — top-center
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.35),
      size.width * 0.65 * intensity,
      Paint()
        ..shader = RadialGradient(
          colors: [
            KiteColors.cyan400.withValues(alpha: 0.12 * intensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height * 0.35),
            radius: size.width * 0.65,
          ),
        ),
    );

    // Gold glow — bottom-right
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.75),
      size.width * 0.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            KiteColors.gold400.withValues(alpha: 0.06 * intensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.8, size.height * 0.75),
            radius: size.width * 0.4,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.intensity != intensity;
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtle grid texture
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KiteColors.navy700.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    const step = 48.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner dots at intersections for a circuit-board feel
    final dotPaint = Paint()
      ..color = KiteColors.cyan400.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Suppress unused import warning for math
// ignore: unused_element
double _unused() => math.pi;
