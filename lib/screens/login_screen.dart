import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show KiteColors;
import '../services/agent_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final agent = context.read<KiteAgentService>();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    bool success;
    if (_isSignUp) {
      success = await agent.signUpWithEmail(email, password, name);
    } else {
      success = await agent.signInWithEmail(email, password);
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(agent.lastError ?? 'Authentication failed.'),
          backgroundColor: KiteColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<KiteAgentService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KiteColors.navy900,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiteColors.cyan400.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KiteColors.navy800,
                              border: Border.all(
                                  color:
                                      KiteColors.cyan400.withValues(alpha: 0.4),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: KiteColors.cyan400
                                        .withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5),
                              ],
                            ),
                            child: const Icon(Icons.paragliding,
                                size: 40, color: KiteColors.cyan400),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                              colors: [KiteColors.white, KiteColors.cyan300],
                              stops: [0.5, 1.0]).createShader(b),
                          child: const Text('KitePay',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1.5)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignUp ? 'Create your account' : 'Welcome back',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: KiteColors.grey400),
                        ),
                        const SizedBox(height: 40),

                        // Name field (sign up only)
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) {
                              return 'Enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              agent.isLoading ? null : _handleSubmit(),
                          validator: (v) {
                            if (v?.isEmpty ?? true) {
                              return 'Enter your password';
                            }
                            if (_isSignUp && (v?.length ?? 0) < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        FilledButton(
                          onPressed: agent.isLoading ? null : _handleSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: KiteColors.cyan400,
                            foregroundColor: KiteColors.navy900,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: agent.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          KiteColors.navy900)))
                              : Text(_isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 20),

                        // Toggle sign in / sign up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: KiteColors.grey400),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp ? 'Sign in' : 'Sign up',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: KiteColors.cyan400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Divider
                        Row(children: [
                          const Expanded(
                              child: Divider(
                                  color: KiteColors.navy700, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: KiteColors.grey600)),
                          ),
                          const Expanded(
                              child: Divider(
                                  color: KiteColors.navy700, thickness: 1)),
                        ]),
                        const SizedBox(height: 20),

                        // Tagline
                        Text(
                          'Fly further with every payment',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: KiteColors.grey600, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 40),
                      ],
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
