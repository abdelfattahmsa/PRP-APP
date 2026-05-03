import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/models.dart';
import '../../../services/supabase_service.dart';

// ── Auth stream — drives reactive rebuilds ─────────────────────
final _supabaseAuthStreamProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// ── Is any user signed in? (used by router) ────────────────────
final authStateProvider = Provider<bool>((ref) {
  ref.watch(_supabaseAuthStreamProvider);
  return Supabase.instance.client.auth.currentUser != null;
});

// ── Is the current user's email verified? ──────────────────────
final isEmailVerifiedProvider = Provider<bool>((ref) {
  ref.watch(_supabaseAuthStreamProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return true; // not relevant when signed out
  return user.emailConfirmedAt != null;
});

// ── Current AppUser — null when signed out ─────────────────────
final currentUserProvider = Provider<AppUser?>((ref) {
  ref.watch(_supabaseAuthStreamProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return AppUser(
    id: user.id,
    email: user.email ?? '',
    fullName: user.userMetadata?['full_name'] as String? ?? '',
    avatarUrl: user.userMetadata?['avatar_url'] as String?,
  );
});

// ══════════════════════════════════════════════════════════════
// AUTH NOTIFIER — sign-in / sign-up / sign-out actions
// ══════════════════════════════════════════════════════════════

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SupabaseService.instance.signUp(
          email: email,
          password: password,
          fullName: fullName,
          username: username,
          phone: phone,
        ).then((_) {}));
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SupabaseService.instance.signIn(
          email: email,
          password: password,
        ).then((_) {}));
  }

  /// Sign in using email, username, or phone.
  /// For username/phone, resolves the email first, then calls signIn.
  Future<void> signInWithIdentifier({
    required String identifier,
    required String password,
    required String method, // 'email' | 'username' | 'phone'
  }) async {
    state = const AsyncLoading();
    String email;
    try {
      if (method == 'username') {
        final found =
            await SupabaseService.instance.getEmailByUsername(identifier);
        if (found == null || found.isEmpty) {
          state = AsyncError(
            Exception('No account found with that username.'),
            StackTrace.current,
          );
          return;
        }
        email = found;
      } else if (method == 'phone') {
        final found =
            await SupabaseService.instance.getEmailByPhone(identifier);
        if (found == null || found.isEmpty) {
          state = AsyncError(
            Exception('No account found with that phone number.'),
            StackTrace.current,
          );
          return;
        }
        email = found;
      } else {
        email = identifier;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return;
    }
    state = await AsyncValue.guard(() => SupabaseService.instance.signIn(
          email: email,
          password: password,
        ).then((_) {}));
  }

  Future<void> resendVerification(String email) async {
    await SupabaseService.instance.resendVerificationEmail(email);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(SupabaseService.instance.signOut);
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => SupabaseService.instance.resetPassword(email));
  }

  Future<void> updateName(String fullName) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => SupabaseService.instance.updateUserName(fullName));
  }

  Future<String> updateAvatar(List<int> bytes, String ext) async {
    return SupabaseService.instance.uploadAvatar(bytes, ext);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
