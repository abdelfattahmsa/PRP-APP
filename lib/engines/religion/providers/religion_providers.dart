import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/religion_models.dart';
import '../data/repositories/religion_repository.dart';

// ── Helpers ──────────────────────────────────────────────────
String _todayStr() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _uid() => Supabase.instance.client.auth.currentUser?.id ?? '';

// ══════════════════════════════════════════════════════════════
// SALAH PROVIDERS
// ══════════════════════════════════════════════════════════════

class TodaySalahNotifier extends AsyncNotifier<SalahRecord> {
  @override
  Future<SalahRecord> build() async {
    final today = _todayStr();
    return await ReligionRepository.instance.getSalahRecord(today) ??
        SalahRecord.forToday(_uid());
  }

  Future<void> togglePrayer(String key) async {
    final current = state.asData?.value;
    if (current == null) return;
    final isDone = current.prayers[key] == true;
    final updated = current.copyWithPrayer(key, !isDone);
    state = AsyncData(updated); // optimistic
    try {
      final saved = await ReligionRepository.instance.upsertSalahRecord(updated);
      state = AsyncData(saved);
    } catch (_) {
      state = AsyncData(current); // rollback
    }
  }
}

final todaySalahProvider =
    AsyncNotifierProvider<TodaySalahNotifier, SalahRecord>(
        TodaySalahNotifier.new);

/// Salah history — last 30 days, newest first
final salahHistoryProvider = FutureProvider<List<SalahRecord>>((ref) =>
    ReligionRepository.instance.getSalahHistory(30));

/// Consecutive days streak — full 5-prayer days
final salahStreakProvider = Provider<int>((ref) {
  final history = ref.watch(salahHistoryProvider).asData?.value ?? [];
  if (history.isEmpty) return 0;

  final byDate = {for (final r in history) r.date: r};
  final today = _todayStr();
  var streak = 0;
  var d = DateTime.now();

  while (true) {
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final rec = byDate[key];
    if (key == today) {
      // Count today even if partial
      if (rec != null && rec.completedCount > 0) streak++;
      d = d.subtract(const Duration(days: 1));
      continue;
    }
    if (rec == null || !rec.isFullDay) break;
    streak++;
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
});

// ══════════════════════════════════════════════════════════════
// QURAN PROVIDERS
// ══════════════════════════════════════════════════════════════

class QuranSessionsNotifier extends AsyncNotifier<List<QuranSession>> {
  @override
  Future<List<QuranSession>> build() =>
      ReligionRepository.instance.getQuranSessions();

  Future<void> add(QuranSession session) async {
    final saved = await ReligionRepository.instance.addQuranSession(session);
    state = AsyncData([saved, ...?state.asData?.value]);
  }

  Future<void> delete(String id) async {
    await ReligionRepository.instance.deleteQuranSession(id);
    state = AsyncData(
      (state.asData?.value ?? []).where((s) => s.id != id).toList(),
    );
  }
}

final quranSessionsProvider =
    AsyncNotifierProvider<QuranSessionsNotifier, List<QuranSession>>(
        QuranSessionsNotifier.new);

/// Total Quran minutes this week
final quranWeekMinutesProvider = Provider<int>((ref) {
  final sessions = ref.watch(quranSessionsProvider).asData?.value ?? [];
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  return sessions
      .where((s) => DateTime.tryParse(s.date)?.isAfter(cutoff) ?? false)
      .fold(0, (sum, s) => sum + s.minutes);
});
