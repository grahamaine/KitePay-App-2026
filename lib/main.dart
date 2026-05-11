import 'dart:math' as math;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
// SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────
class KitePrefsKeys {
  KitePrefsKeys._();
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode'; // 'dark' | 'light' | 'system'
  static const String locale = 'locale'; // e.g. 'en', 'fr', 'es'
  static const String biometricEnabled = 'biometric_enabled';
}

// ─────────────────────────────────────────────────────────────────────────────
// WalletConnect / Reown AppKit provider
// ─────────────────────────────────────────────────────────────────────────────

class KiteWalletProvider extends ChangeNotifier {
  ReownAppKitModal? _modal;
  bool _isConnected = false;
  String? _address;
  String? _chainId;

  bool get isConnected => _isConnected;
  String? get address => _address;
  String? get chainId => _chainId;
  ReownAppKitModal? get modal => _modal;

  /// Short-form display address e.g. 0x1234…abcd
  String get displayAddress {
    if (_address == null || _address!.length < 10) return '';
    return '${_address!.substring(0, 6)}…${_address!.substring(_address!.length - 4)}';
  }

  /// Initialise Reown AppKit. Call once after Firebase.initializeApp().
  Future<void> init(BuildContext context) async {
    _modal = ReownAppKitModal(
      context: context,
      projectId: const String.fromEnvironment(
        'WALLETCONNECT_PROJECT_ID',
        defaultValue: 'YOUR_PROJECT_ID', // replace via --dart-define
      ),
      metadata: const PairingMetadata(
        name: 'KitePay',
        description: 'Fly further with every payment',
        url: 'https://kitepay.app',
        icons: ['https://kitepay.app/icon.png'],
        redirect: Redirect(
          native: 'kitepay://',
          universal: 'https://kitepay.app/wc',
        ),
      ),
      featuredWalletIds: {
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
        '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
        'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
      },
    );

    _modal!.onModalConnect.subscribe(_onConnect);
    _modal!.onModalDisconnect.subscribe(_onDisconnect);
    _modal!.onModalNetworkChange.subscribe(_onNetworkChange);

    await _modal!.init();
    notifyListeners();
  }

  void _onConnect(ModalConnect? event) {
    _isConnected = true;
    _address = event?.session.namespaces?.values
        .expand((ns) => ns.accounts)
        .firstOrNull
        ?.split(':')
        .last;
    _chainId = _modal?.selectedChain?.chainId;
    KiteAnalytics.logEvent(
        'wallet_connected', {'chain': _chainId ?? 'unknown'});
    notifyListeners();
  }

  void _onDisconnect(ModalDisconnect? event) {
    _isConnected = false;
    _address = null;
    _chainId = null;
    KiteAnalytics.logEvent('wallet_disconnected', null);
    notifyListeners();
  }

  void _onNetworkChange(ModalNetworkChange? event) {
    _chainId = event?.chainId;
    notifyListeners();
  }

  /// Open the WalletConnect modal sheet.
  Future<void> openModal(BuildContext context) async {
    if (_modal == null) await init(context);
    _modal!.openModalView();
  }

  /// Disconnect the current session.
  Future<void> disconnect() async {
    await _modal?.disconnect();
  }

  @override
  void dispose() {
    _modal?.onModalConnect.unsubscribe(_onConnect);
    _modal?.onModalDisconnect.unsubscribe(_onDisconnect);
    _modal?.onModalNetworkChange.unsubscribe(_onNetworkChange);
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme provider
// ─────────────────────────────────────────────────────────────────────────────
class KiteThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  KiteThemeProvider(ThemeMode initialMode) : _themeMode = initialMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDark =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

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

  KiteLocaleProvider(Locale initialLocale) : _locale = initialLocale;

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KitePrefsKeys.locale, locale.languageCode);
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('ar'),
    Locale('zh'),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric service
// ─────────────────────────────────────────────────────────────────────────────
class KiteBiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device supports biometrics and has enrolled credentials.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns enrolled biometric types (face, fingerprint, iris).
  static Future<List<BiometricType>> enrolledBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Prompts biometric authentication. Returns true on success.
  static Future<bool> authenticate({
    String localizedReason = 'Authenticate to access KitePay',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics helper
// ─────────────────────────────────────────────────────────────────────────────
class KiteAnalytics {
  KiteAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logEvent(String name, Map<String, Object>? params) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logOnboardingComplete() async {
    await logEvent('onboarding_complete', null);
  }

  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App entry
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init (Crashlytics + Analytics) ───────────────────────────────
  // Crashlytics is not supported on web — guard with kIsWeb
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ── Load persisted preferences ────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  final savedTheme = prefs.getString(KitePrefsKeys.themeMode);
  final initialThemeMode = switch (savedTheme) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark, // default dark for brand identity
  };

  final savedLocale = prefs.getString(KitePrefsKeys.locale);
  final initialLocale =
      savedLocale != null ? Locale(savedLocale) : const Locale('en');

  // ── UI config ─────────────────────────────────────────────────────────────
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
        // Theme
        ChangeNotifierProvider(
          create: (_) => KiteThemeProvider(initialThemeMode),
        ),
        // Locale
        ChangeNotifierProvider(
          create: (_) => KiteLocaleProvider(initialLocale),
        ),
        // Turnkey
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
        // Agent
        ChangeNotifierProxyProvider<TurnkeyProvider, KiteAgentService>(
          create: (ctx) => KiteAgentService(ctx.read<TurnkeyProvider>()),
          update: (_, turnkey, prev) => prev ?? KiteAgentService(turnkey),
        ),
        // WalletConnect
        ChangeNotifierProvider(
          create: (_) => KiteWalletProvider(),
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
    final themeProvider = context.watch<KiteThemeProvider>();
    final localeProvider = context.watch<KiteLocaleProvider>();

    return MaterialApp(
      title: 'KitePay',
      debugShowCheckedModeBanner: false,

      // ── Localisation ───────────────────────────────────────────────────
      locale: localeProvider.locale,
      supportedLocales: KiteLocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Analytics navigator observer ──────────────────────────────────
      navigatorObservers: [KiteAnalytics.observer],

      // ── Theming ────────────────────────────────────────────────────────
      themeMode: themeProvider.themeMode,
      darkTheme: _buildDarkTheme(),
      theme: _buildLightTheme(),

      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme builders (extracted for clarity)
// ─────────────────────────────────────────────────────────────────────────────
ThemeData _buildDarkTheme() {
  return ThemeData(
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
    textTheme: _buildTextTheme(
        KiteColors.white, KiteColors.grey100, KiteColors.grey400),
    filledButtonTheme: _buildFilledButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(),
    textButtonTheme: _buildTextButtonTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(
      fill: KiteColors.navy700,
      border: KiteColors.navy600,
    ),
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
    cardTheme: CardThemeData(
      color: KiteColors.navy800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: KiteColors.navy700, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KiteColors.navy700,
      contentTextStyle: const TextStyle(color: KiteColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    iconTheme: const IconThemeData(color: KiteColors.grey400),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? KiteColors.cyan400
            : KiteColors.grey400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? KiteColors.cyan400.withValues(alpha: 0.3)
            : KiteColors.navy700,
      ),
    ),
  );
}

ThemeData _buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KiteColors.navy800,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: KiteColors.grey100,
    cardColor: KiteColors.white,
    textTheme: _buildTextTheme(
        KiteColors.navy900, KiteColors.navy800, KiteColors.grey600),
    filledButtonTheme: _buildFilledButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(),
    textButtonTheme: _buildTextButtonTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(
      fill: KiteColors.white,
      border: KiteColors.grey400,
    ),
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
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: KiteColors.navy900),
    ),
    cardTheme: CardThemeData(
      color: KiteColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: KiteColors.grey400.withValues(alpha: 0.3), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KiteColors.navy800,
      contentTextStyle: const TextStyle(color: KiteColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextTheme _buildTextTheme(Color primary, Color body, Color subtle) {
  return TextTheme(
    displayLarge: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
        color: primary,
        height: 1.05),
    displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: primary),
    displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: primary),
    headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary),
    headlineMedium:
        TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primary),
    headlineSmall:
        TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
    titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: primary),
    bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, color: body, height: 1.6),
    bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, color: subtle, height: 1.5),
    labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KiteColors.navy900),
  );
}

FilledButtonThemeData _buildFilledButtonTheme() {
  return FilledButtonThemeData(
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
}

OutlinedButtonThemeData _buildOutlinedButtonTheme() {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: KiteColors.cyan400,
      side: const BorderSide(color: KiteColors.cyan400, width: 1.5),
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}

TextButtonThemeData _buildTextButtonTheme() {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: KiteColors.cyan400,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

InputDecorationTheme _buildInputDecorationTheme({
  required Color fill,
  required Color border,
}) {
  return InputDecorationTheme(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate — splash → onboarding? → biometric? → home/login
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
    _bootstrap();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final turnkey = context.read<TurnkeyProvider>();
    await turnkey.ready;

    // Hold splash for at least 1.8 s so the animation completes
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(KitePrefsKeys.onboardingComplete) ?? false;

    if (!onboardingDone) {
      _navigateTo(const OnboardingScreen());
      return;
    }

    // Check if biometric lock is enabled
    final biometricEnabled =
        prefs.getBool(KitePrefsKeys.biometricEnabled) ?? false;

    if (biometricEnabled) {
      final authenticated = await KiteBiometricService.authenticate(
        localizedReason: 'Unlock KitePay to continue',
      );
      if (!mounted) return;
      if (!authenticated) {
        // If biometric fails, fall back to login screen
        _navigateTo(const LoginScreen());
        return;
      }
      KiteAnalytics.logEvent('biometric_auth', {'result': 'success'});
    }

    final session = await turnkey.getSession();
    if (!mounted) return;

    _navigateTo(session != null ? const HomeScreen() : const LoginScreen());
  }

  void _navigateTo(Widget destination) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
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
          const _PulsingBackground(),
          CustomPaint(painter: _GridPainter()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const _KiteLogoMark(size: 100),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _logoFade,
                  child: const _KiteWordmark(),
                ),
                const SizedBox(height: 16),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(KiteColors.cyan400),
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
// Onboarding screen — first-launch walkthrough
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      title: 'Send Money Instantly',
      body:
          'Transfer funds to anyone, anywhere in the world, in seconds — no hidden fees.',
      gradient: [KiteColors.cyan400, KiteColors.cyan500],
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'Bank-Grade Security',
      body:
          'Your assets are protected by Turnkey\'s institutional-grade key management and biometric locks.',
      gradient: [KiteColors.gold300, KiteColors.gold400],
    ),
    _OnboardingPage(
      icon: Icons.auto_graph_rounded,
      title: 'Earn While You Pay',
      body:
          'Every transaction earns KitePoints. Redeem them for cashback, upgrades, and exclusive perks.',
      gradient: [KiteColors.cyan300, KiteColors.gold300],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KitePrefsKeys.onboardingComplete, true);
    await KiteAnalytics.logOnboardingComplete();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: KiteColors.navy900,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PulsingBackground(),
          CustomPaint(painter: _GridPainter()),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 12),
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
                  ),
                ),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? KiteColors.cyan400
                            : KiteColors.navy700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String body;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.gradient,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient halo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  page.gradient.first.withValues(alpha: 0.15),
                  page.gradient.last.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: page.gradient.first.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(page.icon, size: 52, color: page.gradient.first),
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: page.gradient,
            ).createShader(bounds),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: KiteColors.grey400,
                  height: 1.7,
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
          color: Colors.white,
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

// ─────────────────────────────────────────────────────────────────────────────
// WalletConnect button widget — drop into any screen
// ─────────────────────────────────────────────────────────────────────────────
/// A ready-made button that shows connection state and opens the
/// Reown AppKit modal on tap. Drop it anywhere in the widget tree.
///
/// Example usage (e.g. inside HomeScreen's app bar actions):
/// ```dart
///   actions: const [KiteWalletConnectButton()],
/// ```
class KiteWalletConnectButton extends StatelessWidget {
  const KiteWalletConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<KiteWalletProvider>();

    return GestureDetector(
      onTap: () => wallet.openModal(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: wallet.isConnected
              ? KiteColors.success.withValues(alpha: 0.15)
              : KiteColors.navy700,
          border: Border.all(
            color: wallet.isConnected ? KiteColors.success : KiteColors.cyan400,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: wallet.isConnected
                    ? KiteColors.success
                    : KiteColors.grey400,
                boxShadow: wallet.isConnected
                    ? [
                        BoxShadow(
                          color: KiteColors.success.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              wallet.isConnected ? wallet.displayAddress : 'Connect Wallet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: wallet.isConnected
                    ? KiteColors.success
                    : KiteColors.cyan400,
                letterSpacing: 0.2,
              ),
            ),
            if (wallet.isConnected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: KiteColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suppress unused import warning for math
// ─────────────────────────────────────────────────────────────────────────────
// ignore: unused_element
double _unused() => math.pi;
