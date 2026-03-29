import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_text_field.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
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
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const DiamondLogo()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const Gap(24),

                  // Title
                  Text(
                    'Life Plan',
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2),

                  const Gap(6),
                  Text(
                    'ABDELFATTAH M. ABOULFOUTOH · 2026',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                          color: AppColors.goldDim,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms),

                  const Gap(40),

                  // Card
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
                          'Sign In',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Gap(4),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Gap(24),

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
                              v != null && v.length >= 6 ? null : 'Min 6 characters',
                        ),
                        const Gap(8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(Routes.forgotPassword),
                            child: Text(
                              'Forgot password?',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.gold),
                            ),
                          ),
                        ),
                        const Gap(16),

                        AppButton(
                          label: 'Sign In',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                        const Gap(14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            GestureDetector(
                              onTap: () => context.push(Routes.signup),
                              child: Text(
                                'Sign up',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
