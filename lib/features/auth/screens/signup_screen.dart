import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart'
    show AuthBlobs, AuthLogo, AuthGlassCard, AuthField, AuthGradientButton, AuthDivider, AuthErrorBanner, friendlyAuthError;

// ══════════════════════════════════════════════════════════════
// SIGN UP
// ══════════════════════════════════════════════════════════════

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _errorMessage;
  String _passText = '';

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      if (mounted) setState(() => _passText = _passCtrl.text);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      setState(() => _errorMessage = friendlyAuthError(state.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final showRequirements = _passText.isNotEmpty;

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
                        'Create account',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontFamily: 'PlayfairDisplay',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.2),

                      const Gap(6),
                      Text(
                        'Start planning your resources today',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                      const Gap(32),

                      AuthGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthField(
                              controller: _nameCtrl,
                              label: 'Full name',
                              hint: 'Your full name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  v != null && v.isNotEmpty ? null : 'Required',
                            ),
                            const Gap(14),
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
                              validator: (v) {
                                if (v == null || v.length < 8) return 'Min 8 characters';
                                if (!v.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
                                if (!v.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
                                if (!v.contains(RegExp(r'[0-9]'))) return 'Add a number';
                                return null;
                              },
                            ),
                            if (showRequirements) ...[
                              const Gap(10),
                              _PasswordRequirements(_passText),
                            ],
                            const Gap(14),
                            AuthField(
                              controller: _confirmCtrl,
                              label: 'Confirm password',
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              validator: (v) =>
                                  v == _passCtrl.text ? null : 'Passwords do not match',
                            ),
                            if (_errorMessage != null) ...[
                              const Gap(14),
                              AuthErrorBanner(_errorMessage!),
                            ],
                            const Gap(22),
                            AuthGradientButton(
                              label: 'Create Account',
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
                                  'Already have an account?  ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: const Text(
                                    'Sign in',
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

// ── Password requirements live checker ─────────────────────────

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements(this.password);
  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = [
      ('At least 8 characters', password.length >= 8),
      ('Contains uppercase letter', password.contains(RegExp(r'[A-Z]'))),
      ('Contains lowercase letter', password.contains(RegExp(r'[a-z]'))),
      ('Contains a number', password.contains(RegExp(r'[0-9]'))),
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
                                  child: const Icon(
                                    Icons.mark_email_read_outlined,
                                    color: AppColors.success,
                                    size: 26,
                                  ),
                                ),
                                const Gap(16),
                                const Text(
                                  'Reset link sent!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
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
