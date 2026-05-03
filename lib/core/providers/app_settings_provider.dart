import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// ══════════════════════════════════════════════════════════════
// APP SETTINGS — reactive SharedPreferences-backed providers
//
// Each notifier:
//   • reads from SharedPreferences on first build
//   • exposes a set() method that updates state IMMEDIATELY
//     (reactive rebuild everywhere) then persists to prefs async
//
// Usage — write:
//   ref.read(currencyNotifierProvider.notifier).set('USD');
//
// Usage — read (same API as FutureProvider):
//   final currency = ref.watch(currencyNotifierProvider).asData?.value ?? 'EGP';
// ══════════════════════════════════════════════════════════════

// ── Default Currency ──────────────────────────────────────────
class CurrencyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefDefaultCurrency) ?? 'EGP';
  }

  Future<void> set(String value) async {
    state = AsyncData(value); // instant reactive update
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefDefaultCurrency, value);
  }
}

final currencyNotifierProvider =
    AsyncNotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);

// Alias kept for backward-compat with existing watchers
final baseCurrencyProvider = currencyNotifierProvider;

// ── Schedule Mode ─────────────────────────────────────────────
class ScheduleModeNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefScheduleMode) ?? 'normal';
  }

  Future<void> set(String value) async {
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefScheduleMode, value);
  }
}

final scheduleModeNotifierProvider =
    AsyncNotifierProvider<ScheduleModeNotifier, String>(
        ScheduleModeNotifier.new);

// ── Day Start Hour ────────────────────────────────────────────
class DayStartHourNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefDayStartHour) ?? 6;
  }

  Future<void> set(int value) async {
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefDayStartHour, value);
  }
}

final dayStartHourProvider =
    AsyncNotifierProvider<DayStartHourNotifier, int>(DayStartHourNotifier.new);

// ── First Day of Week ─────────────────────────────────────────
class FirstDayOfWeekNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefFirstDayOfWeek) ?? 1; // 1 = Monday
  }

  Future<void> set(int value) async {
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefFirstDayOfWeek, value);
  }
}

final firstDayOfWeekProvider =
    AsyncNotifierProvider<FirstDayOfWeekNotifier, int>(
        FirstDayOfWeekNotifier.new);

// ── Compact Mode ──────────────────────────────────────────────
class CompactModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefCompactMode) ?? false;
  }

  Future<void> set(bool value) async {
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefCompactMode, value);
  }
}

final compactModeProvider =
    AsyncNotifierProvider<CompactModeNotifier, bool>(CompactModeNotifier.new);

// ── Notification toggles ──────────────────────────────────────
class _BoolPrefNotifier extends AsyncNotifier<bool> {
  _BoolPrefNotifier(this._key, this._defaultValue);
  final String _key;
  final bool _defaultValue;

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? _defaultValue;
  }

  Future<void> set(bool value) async {
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final notifyFocusProvider = AsyncNotifierProvider<_BoolPrefNotifier, bool>(
    () => _BoolPrefNotifier(AppConstants.prefNotifyFocus, true));
final notifyGoalsProvider = AsyncNotifierProvider<_BoolPrefNotifier, bool>(
    () => _BoolPrefNotifier(AppConstants.prefNotifyGoals, true));
final notifyHabitsProvider = AsyncNotifierProvider<_BoolPrefNotifier, bool>(
    () => _BoolPrefNotifier(AppConstants.prefNotifyHabits, false));
final notifyFastingProvider = AsyncNotifierProvider<_BoolPrefNotifier, bool>(
    () => _BoolPrefNotifier(AppConstants.prefNotifyFasting, true));
