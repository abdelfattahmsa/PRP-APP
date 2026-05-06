import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

// ── Supported locales ──────────────────────────────────────────────
const kSupportedLocales = [
  Locale('en'),
  Locale('ar'),
];

/// Human-readable locale display names (keyed by languageCode).
const kLocaleNames = {
  'en': 'English',
  'ar': 'العربية',
};

// ── Notifier ───────────────────────────────────────────────────────
class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code != null) {
      return kSupportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => const Locale('en'),
      );
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncData(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
