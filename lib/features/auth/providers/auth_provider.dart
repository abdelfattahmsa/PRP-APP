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
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SupabaseService.instance.signUp(
          email: email,
          password: password,
          fullName: fullName,
        ));
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SupabaseService.instance.signIn(
          email: email,
          password: password,
        ));
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
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
