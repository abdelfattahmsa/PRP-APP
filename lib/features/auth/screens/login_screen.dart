import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

// ── Error parser ───────────────────────────────────────────────
String friendlyAuthError(Object? error) {
  final raw = error?.toString() ?? '';
  final lower = raw.toLowerCase();
  if (lower.contains('invalid login') ||
      lower.contains('invalid_credentials') ||
      lower.contains('invalid credentials')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (lower.contains('email not confirmed') || lower.contains('not confirmed')) {
    return 'Please confirm your email address before signing in.';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already registered') ||
      lower.contains('already exists')) {
    return 'An account with this email already exists. Try signing in instead.';
  }
  if (lower.contains('rate limit') || lower.contains('too many')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (lower.contains('network') ||
      lower.contains('socket') ||
      lower.contains('connection')) {
    return 'Connection error. Check your internet and try again.';
  }
  if (lower.contains('weak password') || lower.contains('password should')) {
    return 'Password is too weak. Use at least 8 characters with mixed case and numbers.';
  }
  if (lower.contains('invalid email') ||
      lower.contains('invalid format') ||
      lower.contains('unable to validate email')) {
    return 'Please enter a valid email address.';
  }
  final match = RegExp(r'(?:message:\s*)([^,\n)]+)').firstMatch(raw);
  if (match != null) {
    final extracted = match.group(1)?.trim() ?? '';
    if (extracted.isNotEmpty && extracted.length < 120) return extracted;
  }
  return 'Something went wrong. Please try again.';
}

// ══════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ══════════════════════════════════════════════════════════════

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      setState(() => _errorMessage = friendlyAuthError(state.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          const AuthBlobs(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AuthLogo()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const Gap(20),

                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontFamily: 'PlayfairDisplay',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.2),

                      const Gap(6),
                      Text(
                        'Sign in to your PRP account',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                        ),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                      const Gap(32),

                      AuthGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthField(
                              controller: _emailCtrl,
                              label: 'Email address',
                              hint: 'you@example.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v != null && v.contains('@') ? null : 'Invalid email',
                            ),
                            const Gap(14),
                            AuthField(
                              controller: _passCtrl,
                              label: 'Password',
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) =>
                                  v != null && v.length >= 6 ? null : 'Min 6 characters',
                            ),
                            const Gap(10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push(Routes.forgotPassword),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const Gap(14),
                              AuthErrorBanner(_errorMessage!),
                            ],
                            const Gap(20),
                            AuthGradientButton(
                              label: 'Sign In',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                            const Gap(20),
                            AuthDivider(),
                            const Gap(20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?  ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push(Routes.signup),
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 500.ms).slideY(begin: 0.15),
                    ],
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

// ══════════════════════════════════════════════════════════════
// SHARED AUTH WIDGETS
// ══════════════════════════════════════════════════════════════

class AuthBlobs extends StatelessWidget {
  const AuthBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            top: -120, right: -120,
            child: Container(
              width: 480, height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160, left: -120,
            child: Container(
              width: 520, height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF6C63FF).withValues(alpha: 0.14), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.gold.withValues(alpha: 0.07), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/prp_logo.png',
      width: 110,
      height: 110,
      fit: BoxFit.contain,
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
        ),
        const Gap(6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Roboto'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
            prefixIcon: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.35)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? AppColors.accentDim : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10), thickness: 1)),
      ],
    );
  }
}

/// Inline error banner shown inside the auth glass card.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const Gap(8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
