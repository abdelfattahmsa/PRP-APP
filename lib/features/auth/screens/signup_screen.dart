// signup_screen.dart
// The sign-up UI now lives inside AuthScreen (login_screen.dart).
// This file keeps SignupScreen and re-exports ForgotPasswordScreen for
// backward-compat with the router.

import 'package:flutter/material.dart';
import 'login_screen.dart';

export 'login_screen.dart' show ForgotPasswordScreen;

/// Opens the combined AuthScreen pre-navigated to the Sign Up tab.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthScreen(initialTab: 1);
}
