import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return 'Incorrect credentials. Please try again.';
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
  if (lower.contains('no account found with that username')) {
    return 'No account found with that username.';
  }
  if (lower.contains('no account found with that phone')) {
    return 'No account found with that phone number.';
  }
  final match = RegExp(r'(?:message:\s*)([^,\n)]+)').firstMatch(raw);
  if (match != null) {
    final extracted = match.group(1)?.trim() ?? '';
    if (extracted.isNotEmpty && extracted.length < 120) return extracted;
  }
  return 'Something went wrong. Please try again.';
}

// ══════════════════════════════════════════════════════════════
// COMBINED AUTH SCREEN  (Sign In + Sign Up in one place)
// ══════════════════════════════════════════════════════════════

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialTab = 0});

  /// 0 = Sign In tab, 1 = Sign Up tab
  final int initialTab;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // ── Tab ──────────────────────────────────────────────────────
  late int _tab; // 0 = sign in | 1 = sign up

  // ── Sign In ──────────────────────────────────────────────────
  int _signInMethod = 0; // 0 = email | 1 = username | 2 = phone
  final _siIdCtrl    = TextEditingController();
  final _siPassCtrl  = TextEditingController();
  final _siFormKey   = GlobalKey<FormState>();
  bool  _siObscure   = true;
  String? _siError;

  // ── Sign Up ──────────────────────────────────────────────────
  final _suNameCtrl    = TextEditingController();
  final _suEmailCtrl   = TextEditingController();
  final _suUsernameCtrl = TextEditingController();
  final _suPhoneCtrl   = TextEditingController();
  final _suPassCtrl    = TextEditingController();
  final _suConfirmCtrl = TextEditingController();
  final _suFormKey     = GlobalKey<FormState>();
  bool  _suObscure     = true;
  String? _suError;
  String  _passText    = '';
  bool    _checkEmail  = false;
  String  _checkEmailAddr = '';
  bool    _resendSent  = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _suPassCtrl.addListener(() {
      if (mounted) setState(() => _passText = _suPassCtrl.text);
    });
  }

  @override
  void dispose() {
    _siIdCtrl.dispose(); _siPassCtrl.dispose();
    _suNameCtrl.dispose(); _suEmailCtrl.dispose();
    _suUsernameCtrl.dispose(); _suPhoneCtrl.dispose();
    _suPassCtrl.dispose(); _suConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _siError = null);
    if (!_siFormKey.currentState!.validate()) return;
    final methods = ['email', 'username', 'phone'];
    await ref.read(authNotifierProvider.notifier).signInWithIdentifier(
      identifier: _siIdCtrl.text.trim(),
      password:   _siPassCtrl.text,
      method:     methods[_signInMethod],
    );
    final st = ref.read(authNotifierProvider);
    if (st.hasError && mounted) {
      setState(() => _siError = friendlyAuthError(st.error));
    }
    // Navigation is handled by GoRouter's redirect on auth state change
  }

  Future<void> _signUp() async {
    setState(() => _suError = null);
    if (!_suFormKey.currentState!.validate()) return;

    final username = _suUsernameCtrl.text.trim();
    final phone    = _suPhoneCtrl.text.trim();

    await ref.read(authNotifierProvider.notifier).signUp(
      email:    _suEmailCtrl.text.trim(),
      password: _suPassCtrl.text,
      fullName: _suNameCtrl.text.trim(),
      username: username.isEmpty ? null : username,
      phone:    phone.isEmpty    ? null : phone,
    );
    final st = ref.read(authNotifierProvider);
    if (st.hasError && mounted) {
      setState(() => _suError = friendlyAuthError(st.error));
      return;
    }
    if (mounted) {
      // If no session was created (email confirmation required), show
      // "check your email" state. Otherwise router redirect handles navigation.
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      if (!hasSession) {
        setState(() {
          _checkEmail     = true;
          _checkEmailAddr = _suEmailCtrl.text.trim();
          _resendSent     = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    await ref.read(authNotifierProvider.notifier).resendVerification(_checkEmailAddr);
    if (mounted) setState(() => _resendSent = true);
  }

  void _switchTab(int idx) {
    setState(() {
      _tab        = idx;
      _siError    = null;
      _suError    = null;
      _checkEmail = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo ──
                    const AuthLogo()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const Gap(20),

                    // ── Tab Switcher ──
                    _AuthTabBar(
                      current: _tab,
                      onChanged: _switchTab,
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    const Gap(24),

                    // ── Content (animated switch) ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _tab == 0
                          ? _buildSignIn(isLoading)
                          : _checkEmail
                              ? _buildCheckEmail()
                              : _buildSignUp(isLoading),
                    ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign In Form ──────────────────────────────────────────────

  Widget _buildSignIn(bool isLoading) {
    final methods = [
      (label: 'Email',    icon: Icons.mail_outline_rounded,   hint: 'you@example.com',  keyboard: TextInputType.emailAddress),
      (label: 'Username', icon: Icons.alternate_email_rounded, hint: '@yourname',        keyboard: TextInputType.text),
      (label: 'Phone',    icon: Icons.phone_outlined,          hint: '+1 234 567 8900',  keyboard: TextInputType.phone),
    ];
    final m = methods[_signInMethod];

    return AuthGlassCard(
      key: const ValueKey('signin'),
      child: Form(
        key: _siFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Method pills
            _MethodPills(
              selected: _signInMethod,
              labels: ['Email', 'Username', 'Phone'],
              onSelected: (i) => setState(() {
                _signInMethod = i;
                _siIdCtrl.clear();
                _siError = null;
              }),
            ),
            const Gap(18),

            // Identifier field
            AuthField(
              controller: _siIdCtrl,
              label: m.label,
              hint: m.hint,
              icon: m.icon,
              keyboardType: m.keyboard,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (_signInMethod == 0 && !v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const Gap(14),

            // Password
            AuthField(
              controller: _siPassCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _siObscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _siObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                onPressed: () => setState(() => _siObscure = !_siObscure),
              ),
              validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
            ),

            // Forgot password
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

            if (_siError != null) ...[
              const Gap(14),
              AuthErrorBanner(_siError!),
            ],

            const Gap(20),
            AuthGradientButton(
              label: 'Sign In',
              isLoading: isLoading,
              onPressed: _signIn,
            ),
            const Gap(20),
            const AuthDivider(),
            const Gap(16),
            _switchHint(
              label: "Don't have an account?",
              action: 'Sign up',
              onTap: () => _switchTab(1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sign Up Form ──────────────────────────────────────────────

  Widget _buildSignUp(bool isLoading) {
    return AuthGlassCard(
      key: const ValueKey('signup'),
      child: Form(
        key: _suFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full name (required)
            AuthField(
              controller: _suNameCtrl,
              label: 'Full name',
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
            ),
            const Gap(14),

            // Email (required)
            AuthField(
              controller: _suEmailCtrl,
              label: 'Email address',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
            ),
            const Gap(14),

            // Username (optional)
            AuthField(
              controller: _suUsernameCtrl,
              label: 'Username',
              hint: 'Optional — used to sign in',
              icon: Icons.alternate_email_rounded,
              isOptional: true,
              keyboardType: TextInputType.text,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                if (v.trim().length < 3) return 'Min 3 characters';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                  return 'Letters, numbers, underscores only';
                }
                return null;
              },
            ),
            const Gap(14),

            // Phone (optional)
            AuthField(
              controller: _suPhoneCtrl,
              label: 'Phone number',
              hint: 'Optional — used to sign in',
              icon: Icons.phone_outlined,
              isOptional: true,
              keyboardType: TextInputType.phone,
            ),
            const Gap(14),

            // Password
            AuthField(
              controller: _suPassCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _suObscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _suObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                onPressed: () => setState(() => _suObscure = !_suObscure),
              ),
              validator: (v) {
                if (v == null || v.length < 8) return 'Min 8 characters';
                if (!v.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
                if (!v.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
                if (!v.contains(RegExp(r'[0-9]'))) return 'Add a number';
                return null;
              },
            ),
            if (_passText.isNotEmpty) ...[
              const Gap(10),
              _PasswordRequirements(_passText),
            ],
            const Gap(14),

            // Confirm password
            AuthField(
              controller: _suConfirmCtrl,
              label: 'Confirm password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _suObscure,
              validator: (v) => v == _suPassCtrl.text ? null : 'Passwords do not match',
            ),

            if (_suError != null) ...[
              const Gap(14),
              AuthErrorBanner(_suError!),
            ],

            const Gap(22),
            AuthGradientButton(
              label: 'Create Account',
              isLoading: isLoading,
              onPressed: _signUp,
            ),
            const Gap(20),
            const AuthDivider(),
            const Gap(16),
            _switchHint(
              label: 'Already have an account?',
              action: 'Sign in',
              onTap: () => _switchTab(0),
            ),
          ],
        ),
      ),
    );
  }

  // ── Check Email State ─────────────────────────────────────────

  Widget _buildCheckEmail() {
    return AuthGlassCard(
      key: const ValueKey('check-email'),
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppColors.accent, size: 28),
          ),
          const Gap(16),
          const Text(
            'Check your inbox',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const Gap(8),
          Text(
            'We sent a verification link to',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const Gap(4),
          Text(
            _checkEmailAddr,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          Text(
            "Click the link in the email to activate your account.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),

          if (_resendSent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: AppColors.success),
                  const Gap(8),
                  Text(
                    'Verification email resent!',
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            AuthGradientButton(
              label: 'Resend verification email',
              isLoading: ref.watch(authNotifierProvider).isLoading,
              onPressed: _resendVerification,
            ),

          const Gap(16),
          GestureDetector(
            onTap: () => _switchTab(0),
            child: Text(
              '← Back to Sign In',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────

  Widget _switchHint({
    required String label,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label  ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Thin wrappers kept for router compatibility ────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const AuthScreen(initialTab: 0);
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
      width: 110, height: 110,
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
    this.isOptional = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (isOptional) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'optional',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.3),
                    fontFamily: 'Roboto',
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
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
                    blurRadius: 20, spreadRadius: -4,
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
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600, letterSpacing: 0.2,
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

// ══════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ══════════════════════════════════════════════════════════════

/// Sign In / Sign Up tab switcher pill.
class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _tab('Sign In', 0),
          _tab('Sign Up', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int idx) {
    final active = current == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

/// Email / Username / Phone method pills for sign in.
class _MethodPills extends StatelessWidget {
  const _MethodPills({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });
  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const Gap(6),
          Expanded(child: _pill(labels[i], i)),
        ],
      ],
    );
  }

  Widget _pill(String label, int idx) {
    final active = selected == idx;
    return GestureDetector(
      onTap: () => onSelected(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Live password requirement checker.
class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements(this.password);
  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = [
      ('At least 8 characters',      password.length >= 8),
      ('Contains uppercase letter',  password.contains(RegExp(r'[A-Z]'))),
      ('Contains lowercase letter',  password.contains(RegExp(r'[a-z]'))),
      ('Contains a number',          password.contains(RegExp(r'[0-9]'))),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 0.3,
            ),
          ),
          const Gap(8),
          ...checks.map((c) => _RequirementRow(c.$1, c.$2)),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow(this.label, this.met);
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              key: ValueKey(met),
              size: 14,
              color: met ? AppColors.success : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          const Gap(7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.success : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FORGOT PASSWORD
// ══════════════════════════════════════════════════════════════

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = friendlyAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuthLogo()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const Gap(20),
                    Text(
                      _sent ? 'Check your inbox' : 'Reset password',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                    const Gap(6),
                    Text(
                      _sent
                          ? 'A reset link was sent to ${_emailCtrl.text}'
                          : "Enter your email and we'll send a reset link",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 250.ms),
                    const Gap(32),
                    AuthGlassCard(
                      child: _sent
                          ? Column(
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success.withValues(alpha: 0.12),
                                  ),
                                  child: const Icon(Icons.mark_email_read_outlined,
                                      color: AppColors.success, size: 26),
                                ),
                                const Gap(16),
                                const Text(
                                  'Reset link sent!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600, fontSize: 16,
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  "Check your spam folder if you don't see it.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Gap(24),
                                AuthGradientButton(
                                  label: 'Back to Sign In',
                                  onPressed: () => context.pop(),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthField(
                                  controller: _emailCtrl,
                                  label: 'Email address',
                                  hint: 'you@example.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                if (_errorMessage != null) ...[
                                  const Gap(14),
                                  AuthErrorBanner(_errorMessage!),
                                ],
                                const Gap(20),
                                AuthGradientButton(
                                  label: 'Send Reset Link',
                                  isLoading: isLoading,
                                  onPressed: _submit,
                                ),
                                const Gap(16),
                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.pop(),
                                    child: Text(
                                      '← Back to Sign In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ).animate().fadeIn(delay: 350.ms, duration: 500.ms).slideY(begin: 0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
