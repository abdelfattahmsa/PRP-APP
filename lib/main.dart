import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM ERROR: $error');
    debugPrint('$stack');
    return true;
  };

  // Initialise Supabase for DATA only (auth handled by Clerk)
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  tz.initializeTimeZones();

  // Initialise Clerk — wrap in try/catch so a domain/network error
  // doesn't crash the whole app before the widget tree is built.
  ClerkAuthState? clerkState;
  Object? clerkInitError;
  try {
    clerkState = await ClerkAuthState.create(
      config: ClerkAuthConfig(
        publishableKey: AppConstants.clerkPublishableKey,
      ),
    );
    // Bridge Clerk user ID → SupabaseService so RLS queries use Clerk UID
    SupabaseService.instance.setClerkUserId(clerkState.user?.id);
    clerkState.addListener(() {
      SupabaseService.instance.setClerkUserId(clerkState?.user?.id);
    });
  } catch (e, st) {
    clerkInitError = e;
    debugPrint('CLERK INIT ERROR: $e\n$st');
  }

  if (clerkState == null) {
    // Clerk failed to initialise — show a minimal error screen
    runApp(_ClerkErrorApp(error: clerkInitError));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        clerkAuthProvider.overrideWith((_) => clerkState!),
      ],
      child: ClerkAuth(
        authState: clerkState,
        child: const PRPApp(),
      ),
    ),
  );
}

class PRPApp extends ConsumerWidget {
  const PRPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

// Shown only when Clerk fails to initialise (domain mismatch, network, etc.)
class _ClerkErrorApp extends StatelessWidget {
  const _ClerkErrorApp({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF22C55E), size: 48),
                const SizedBox(height: 24),
                const Text(
                  'Authentication unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not connect to the authentication service.\n'
                  'Check your internet connection and try again.\n\n'
                  '${error ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
