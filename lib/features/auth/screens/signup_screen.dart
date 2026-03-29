// ── signup_screen.dart ────────────────────────────────────────
// lib/features/auth/screens/signup_screen.dart

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
                  const DiamondLogo().animate().fadeIn(duration: 600.ms),
                  const Gap(20),
                  Text('Create Account',
                      style: Theme.of(context).textTheme.headlineLarge)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const Gap(28),
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
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Abdelfattah M. Aboulfoutoh',
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
                            Text('Already have an account? ',
                                style: Theme.of(context).textTheme.bodySmall),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text('Sign in',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ── forgot_password_screen.dart ───────────────────────────────
// lib/features/auth/screens/forgot_password_screen.dart

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
