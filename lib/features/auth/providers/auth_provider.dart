import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../shared/models/models.dart';

// ══════════════════════════════════════════════════════════════
// CLERK AUTH PROVIDER
// Holds the ClerkAuthState instance — overridden in main.dart
// via ProviderScope.overrides after async initialisation.
// ══════════════════════════════════════════════════════════════

final clerkAuthProvider = ChangeNotifierProvider<ClerkAuthState>((ref) {
  throw StateError(
    'clerkAuthProvider must be overridden in ProviderScope in main.dart',
  );
});

// ── Derived: is any user signed in ────────────────────────────
final authStateProvider = Provider<bool>((ref) {
  return ref.watch(clerkAuthProvider).isSignedIn;
});

// ── Derived: current AppUser from Clerk user object ────────────
final currentUserProvider = Provider<AppUser?>((ref) {
  final clerkState = ref.watch(clerkAuthProvider);
  final user = clerkState.user;
  if (user == null) return null;
  return AppUser(
    id: user.id,
    email: (user.emailAddresses?.isNotEmpty == true)
        ? user.emailAddresses!.first.emailAddress
        : '',
    fullName: [user.firstName, user.lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' '),
    avatarUrl: user.profileImageUrl ?? user.imageUrl,
  );
});

// ══════════════════════════════════════════════════════════════
// AUTH NOTIFIER — sign-in / sign-up / sign-out actions
// ══════════════════════════════════════════════════════════════

class AuthNotifier extends AsyncNotifier<void> {
  ClerkAuthState get _clerk => ref.read(clerkAuthProvider);

  @override
  Future<void> build() async {}

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final parts = fullName.trim().split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.skip(1).join(' ') : null;
      await _clerk.attemptSignUp(
        strategy: clerk.Strategy.password,
        emailAddress: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _clerk.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _clerk.signOut());
  }

  Future<void> resetPassword(String email) async {
    // Clerk password reset is initiated via email — use Clerk's flow
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _clerk.attemptSignIn(
        strategy: clerk.Strategy.resetPasswordEmailCode,
        identifier: email,
      );
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
