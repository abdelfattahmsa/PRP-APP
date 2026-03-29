import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/models/models.dart';

/// Streams the current auth state from Supabase
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseService.instance.authStateStream.map((s) => s.session?.user);
});

/// Current logged-in user model
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return null;
  return SupabaseService.instance.getProfile();
});

/// Auth actions notifier
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance
          .signUp(email: email, password: password, fullName: fullName)
          .then((_) {}),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance
          .signIn(email: email, password: password)
          .then((_) {}),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(SupabaseService.instance.signOut);
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance.resetPassword(email),
    );
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
