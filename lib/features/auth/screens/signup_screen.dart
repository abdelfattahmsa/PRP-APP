import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _PRPLogo(size: 72)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const Gap(20),
                  Text(
                    'PRP',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontFamily: 'PlayfairDisplay',
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2),
                  const Gap(6),
                  Text(
                    'Personal Resource Planner',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const Gap(32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Gap(4),
                        Text(
                          'Start planning your resources',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Gap(24),
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Your full name',
                          validator: (v) =>
                              v != null && v.isNotEmpty ? null : 'Required',
                        ),
                        const Gap(14),
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v != null && v.contains('@') ? null : 'Invalid email',
                        ),
                        const Gap(14),
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: '••••••••',
                          obscureText: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) =>
                              v != null && v.length >= 8 ? null : 'Min 8 characters',
                        ),
                        const Gap(14),
                        AppTextField(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          hint: '••••••••',
                          obscureText: _obscure,
                          validator: (v) => v == _passCtrl.text
                              ? null
                              : 'Passwords do not match',
                        ),
                        const Gap(20),
                        AppButton(
                          label: 'Create Account',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                        const Gap(14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Sign in',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Forgot Password ────────────────────────────────────────────

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(_emailCtrl.text.trim());
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _sent
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          color: AppColors.success, size: 48),
                      const Gap(16),
                      Text('Check your email',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Gap(8),
                      Text(
                        'We sent a reset link to ${_emailCtrl.text}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(24),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back to Sign In'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Forgot Password?',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Gap(8),
                      Text(
                        "Enter your email and we'll send a reset link.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Gap(24),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Gap(20),
                      AppButton(
                        label: 'Send Reset Link',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── PRP Logo Mark ──────────────────────────────────────────────

class _PRPLogo extends StatelessWidget {
  const _PRPLogo({this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'PRP',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PlayfairDisplay',
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
