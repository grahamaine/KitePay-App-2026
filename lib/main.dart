import 'dart:math' as math;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/agent_service.dart';
import 'services/identity_service.dart';
import 'services/kite_chain_service.dart';
import 'services/usdc_service.dart';
import 'services/x402_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand tokens
// ─────────────────────────────────────────────────────────────────────────────
class KiteColors {
  KiteColors._();
  static const Color navy900 = Color(0xFF050D1A);
  static const Color navy800 = Color(0xFF0A1628);
  static const Color navy700 = Color(0xFF0F2040);
  static const Color navy600 = Color(0xFF142B58);
  static const Color cyan400 = Color(0xFF00E5FF);
  static const Color cyan300 = Color(0xFF4DFBFF);
  static const Color cyan500 = Color(0xFF00B8D4);
  static const Color gold400 = Color(0xFFFFCA28);
  static const Color gold300 = Color(0xFFFFE082);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF5F7FA);
  static const Color grey400 = Color(0xFF9AA5B4);
  static const Color grey600 = Color(0xFF627D98);
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
}

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────
class KitePrefsKeys {
  KitePrefsKeys._();
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics — web-safe
// ─────────────────────────────────────────────────────────────────────────────
class KiteAnalytics {
  KiteAnalytics._();
  static FirebaseAnalytics? _instance;
  static FirebaseAnalytics get _analytics {
    _instance ??= FirebaseAnalytics.instance;
    return _instance!;
  }

  static NavigatorObserver get observer => kIsWeb
      ? RouteObserver<PageRoute>()
      : FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logEvent(String name, Map<String, Object>? params) async {
    if (kIsWeb) return;
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logScreenView(String screenName) async =>
      logEvent('screen_view', {'screen_name': screenName});

  static Future<void> logLogin(String method) async {
    if (kIsWeb) return;
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  static Future<void> logOnboardingComplete() async =>
      logEvent('onboarding_complete', null);

  static Future<void> setUserId(String? userId) async {
    if (kIsWeb) return;
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme provider
// ─────────────────────────────────────────────────────────────────────────────
class KiteThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  KiteThemeProvider(ThemeMode initial) : _themeMode = initial;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KitePrefsKeys.themeMode, mode.name);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locale provider
// ─────────────────────────────────────────────────────────────────────────────
class KiteLocaleProvider extends ChangeNotifier {
  Locale _locale;
  KiteLocaleProvider(Locale initial) : _locale = initial;
  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('ar'),
    Locale('zh'),
  ];

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KitePrefsKeys.locale, locale.languageCode);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App entry
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}\n${details.stack}');
  };

  // Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Preferences
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString(KitePrefsKeys.themeMode);
  final initialThemeMode = switch (savedTheme) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
  final savedLocale = prefs.getString(KitePrefsKeys.locale);
  final initialLocale =
      savedLocale != null ? Locale(savedLocale) : const Locale('en');

  // System UI
  if (!kIsWeb) {
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
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => KiteThemeProvider(initialThemeMode)),
        ChangeNotifierProvider(
            create: (_) => KiteLocaleProvider(initialLocale)),
        ChangeNotifierProvider(create: (_) => KiteAgentService()),
        ChangeNotifierProvider(create: (_) => KiteChainService()),
        ChangeNotifierProvider(create: (_) => UsdcService()..initialize()),
        ChangeNotifierProxyProvider<UsdcService, X402Service>(
          create: (ctx) => X402Service(ctx.read<UsdcService>()),
          update: (_, usdc, prev) => prev ?? X402Service(usdc),
        ),
        ChangeNotifierProvider(create: (_) => IdentityService()..initialize()),
      ],
      child: const KitePayApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────
class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<KiteThemeProvider>();
    final locale = context.watch<KiteLocaleProvider>();

    return MaterialApp(
      title: 'KitePay',
      debugShowCheckedModeBanner: false,
      locale: locale.locale,
      supportedLocales: KiteLocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [KiteAnalytics.observer],
      themeMode: theme.themeMode,
      darkTheme: _buildDarkTheme(),
      theme: _buildLightTheme(),
      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme builders
// ─────────────────────────────────────────────────────────────────────────────
ThemeData _buildDarkTheme() => ThemeData(
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
      textTheme:
          _textTheme(KiteColors.white, KiteColors.grey100, KiteColors.grey400),
      filledButtonTheme: _filledBtn(),
      outlinedButtonTheme: _outlinedBtn(),
      textButtonTheme: _textBtn(),
      inputDecorationTheme: _inputTheme(KiteColors.navy700, KiteColors.navy600),
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
            letterSpacing: -0.3),
        iconTheme: IconThemeData(color: KiteColors.white),
      ),
      cardTheme: CardThemeData(
        color: KiteColors.navy800,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: KiteColors.navy700, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KiteColors.navy700,
        contentTextStyle: const TextStyle(color: KiteColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: KiteColors.grey400),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? KiteColors.cyan400
                : KiteColors.grey400),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? KiteColors.cyan400.withValues(alpha: 0.3)
                : KiteColors.navy700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KiteColors.navy800,
        indicatorColor: KiteColors.cyan400.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected)
                  ? KiteColors.cyan400
                  : KiteColors.grey400,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? KiteColors.cyan400
                  : KiteColors.grey400,
            )),
      ),
    );

ThemeData _buildLightTheme() => ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          seedColor: KiteColors.navy800, brightness: Brightness.light),
      scaffoldBackgroundColor: KiteColors.grey100,
      cardColor: KiteColors.white,
      textTheme: _textTheme(
          KiteColors.navy900, KiteColors.navy800, KiteColors.grey600),
      filledButtonTheme: _filledBtn(),
      outlinedButtonTheme: _outlinedBtn(),
      textButtonTheme: _textBtn(),
      inputDecorationTheme: _inputTheme(KiteColors.white, KiteColors.grey400),
      appBarTheme: const AppBarTheme(
        backgroundColor: KiteColors.white,
        foregroundColor: KiteColors.navy900,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KiteColors.navy900,
            letterSpacing: -0.3),
        iconTheme: IconThemeData(color: KiteColors.navy900),
      ),
      cardTheme: CardThemeData(
        color: KiteColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: KiteColors.grey400.withValues(alpha: 0.3), width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KiteColors.navy800,
        contentTextStyle: const TextStyle(color: KiteColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );

TextTheme _textTheme(Color p, Color b, Color s) => TextTheme(
      displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          color: p,
          height: 1.05),
      displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: p),
      displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: p),
      headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: p),
      headlineMedium:
          TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: p),
      headlineSmall:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p),
      titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: p),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: b, height: 1.6),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, color: s, height: 1.5),
      labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: KiteColors.navy900),
    );

FilledButtonThemeData _filledBtn() => FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KiteColors.cyan400,
        foregroundColor: KiteColors.navy900,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        elevation: 0,
      ),
    );

OutlinedButtonThemeData _outlinedBtn() => OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KiteColors.cyan400,
        side: const BorderSide(color: KiteColors.cyan400, width: 1.5),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );

TextButtonThemeData _textBtn() => TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KiteColors.cyan400,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );

InputDecorationTheme _inputTheme(Color fill, Color border) =>
    InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KiteColors.cyan400, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KiteColors.error, width: 1.5)),
      labelStyle: const TextStyle(color: KiteColors.grey400),
      hintStyle: const TextStyle(color: KiteColors.grey600),
      prefixIconColor: KiteColors.grey400,
    );

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate — checks Firebase auth state
// ─────────────────────────────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale, _logoFade, _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut)));
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut)));
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.45, 0.75, curve: Curves.easeOut)));
    _ctrl.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (!(prefs.getBool(KitePrefsKeys.onboardingComplete) ?? false)) {
        _go(const OnboardingScreen());
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _go(const HomeScreen());
        return;
      }

      _go(const LoginScreen());
    } catch (e) {
      debugPrint('Bootstrap error: $e');
      if (mounted) _go(const LoginScreen());
    }
  }

  void _go(Widget dest) =>
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, a, __) => dest,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      body: Stack(fit: StackFit.expand, children: [
        const _PulsingBackground(),
        CustomPaint(painter: _GridPainter()),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                    scale: _logoScale, child: const _KiteLogoMark(size: 100))),
            const SizedBox(height: 28),
            FadeTransition(opacity: _logoFade, child: const _KiteWordmark()),
            const SizedBox(height: 16),
            FadeTransition(
                opacity: _taglineFade,
                child: SlideTransition(
                    position: _taglineSlide,
                    child: Text('Fly further with every payment',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: KiteColors.grey400, letterSpacing: 0.5)))),
          ]),
        ),
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
                                KiteColors.cyan400)))))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _OBPage(
        icon: Icons.rocket_launch_rounded,
        title: 'Send Money Instantly',
        body:
            'Transfer funds to anyone, anywhere in the world, in seconds — no hidden fees.',
        gradient: [KiteColors.cyan400, KiteColors.cyan500]),
    _OBPage(
        icon: Icons.shield_rounded,
        title: 'Bank-Grade Security',
        body:
            'Your assets are protected by institutional-grade key management and biometric locks.',
        gradient: [KiteColors.gold300, KiteColors.gold400]),
    _OBPage(
        icon: Icons.auto_graph_rounded,
        title: 'Earn While You Pay',
        body:
            'Every transaction earns KitePoints. Redeem them for cashback, upgrades, and exclusive perks.',
        gradient: [KiteColors.cyan300, KiteColors.gold300]),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KitePrefsKeys.onboardingComplete, true);
    await KiteAnalytics.logOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => const LoginScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      body: Stack(fit: StackFit.expand, children: [
        const _PulsingBackground(),
        CustomPaint(painter: _GridPainter()),
        SafeArea(
            child: Column(children: [
          Align(
              alignment: Alignment.centerRight,
              child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 12),
                  child: TextButton(
                      onPressed: _finish, child: const Text('Skip')))),
          Expanded(
              child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _OBPageView(page: _pages[i]),
          )),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _page == i
                                ? KiteColors.cyan400
                                : KiteColors.navy700,
                            borderRadius: BorderRadius.circular(4)),
                      ))),
          const SizedBox(height: 32),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton(
                  onPressed: isLast
                      ? _finish
                      : () => _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut),
                  child: Text(isLast ? 'Get Started' : 'Next'))),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }
}

class _OBPage {
  final IconData icon;
  final String title, body;
  final List<Color> gradient;
  const _OBPage(
      {required this.icon,
      required this.title,
      required this.body,
      required this.gradient});
}

class _OBPageView extends StatelessWidget {
  final _OBPage page;
  const _OBPageView({required this.page});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    page.gradient.first.withValues(alpha: 0.15),
                    page.gradient.last.withValues(alpha: 0.05)
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(
                      color: page.gradient.first.withValues(alpha: 0.4),
                      width: 1.5)),
              child: Icon(page.icon, size: 52, color: page.gradient.first)),
          const SizedBox(height: 40),
          ShaderMask(
              shaderCallback: (b) =>
                  LinearGradient(colors: page.gradient).createShader(b),
              child: Text(page.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: Colors.white))),
          const SizedBox(height: 16),
          Text(page.body,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: KiteColors.grey400, height: 1.7)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo mark
// ─────────────────────────────────────────────────────────────────────────────
class _KiteLogoMark extends StatelessWidget {
  final double size;
  const _KiteLogoMark({required this.size});
  @override
  Widget build(BuildContext context) => Container(
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
                  spreadRadius: 8),
              BoxShadow(
                  color: KiteColors.cyan400.withValues(alpha: 0.1),
                  blurRadius: 80,
                  spreadRadius: 20),
            ]),
        child: Center(
            child: CustomPaint(
                size: Size(size * 0.5, size * 0.5),
                painter: _DiamondPainter())),
      );
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawPath(
        Path()
          ..moveTo(cx, 0)
          ..lineTo(size.width, cy * 1.1)
          ..lineTo(cx, size.height)
          ..lineTo(0, cy * 1.1)
          ..close(),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [KiteColors.cyan300, KiteColors.cyan500])
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    final lp = Paint()
      ..color = KiteColors.navy900.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), lp);
    canvas.drawLine(Offset(0, cy * 1.1), Offset(size.width, cy * 1.1), lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Wordmark
// ─────────────────────────────────────────────────────────────────────────────
class _KiteWordmark extends StatelessWidget {
  const _KiteWordmark();
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (b) => const LinearGradient(
            colors: [KiteColors.white, KiteColors.cyan300],
            stops: [0.5, 1.0]).createShader(b),
        child: const Text('KitePay',
            style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing background
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingBackground extends StatefulWidget {
  const _PulsingBackground();
  @override
  State<_PulsingBackground> createState() => _PulsingBGState();
}

class _PulsingBGState extends State<_PulsingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _p;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _p = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _p,
      builder: (_, __) => CustomPaint(painter: _GlowPainter(_p.value)));
}

class _GlowPainter extends CustomPainter {
  final double i;
  _GlowPainter(this.i);
  @override
  void paint(Canvas canvas, Size size) {
    _glow(canvas, size, Offset(size.width / 2, size.height * 0.35),
        size.width * 0.65 * i, KiteColors.cyan400.withValues(alpha: 0.12 * i));
    _glow(canvas, size, Offset(size.width * 0.8, size.height * 0.75),
        size.width * 0.4, KiteColors.gold400.withValues(alpha: 0.06 * i));
  }

  void _glow(Canvas c, Size s, Offset center, double radius, Color color) {
    c.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, Colors.transparent])
              .createShader(Rect.fromCircle(center: center, radius: radius)));
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.i != i;
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid painter
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = KiteColors.navy700.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final dp = Paint()
      ..color = KiteColors.cyan400.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ignore: unused_element
double _unused() => math.pi;
