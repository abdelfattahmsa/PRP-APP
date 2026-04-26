import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/checkin_models.dart';
import '../data/repositories/checkin_repository.dart';

const _uuid = Uuid();

String _todayStr() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Today's check-in ────────────────────────────────────────────
final todayCheckinProvider =
    AsyncNotifierProvider<TodayCheckinNotifier, DailyCheckin?>(
  TodayCheckinNotifier.new,
);

class TodayCheckinNotifier extends AsyncNotifier<DailyCheckin?> {
  @override
  Future<DailyCheckin?> build() =>
      CheckinRepository.instance.getTodayCheckin(_todayStr());

  Future<void> saveMorning({
    required int energy,
    required String priority,
  }) async {
    final existing = state.asData?.value;
    final checkin = (existing ?? DailyCheckin(id: _uuid.v4(), date: _todayStr()))
        .copyWith(morningEnergy: energy, topPriority: priority);
    state = const AsyncLoading();
    final saved = await CheckinRepository.instance.upsertCheckin(checkin);
    state = AsyncData(saved);
  }

  Future<void> saveEvening({
    required int mood,
    required String accomplishment,
  }) async {
    final existing = state.asData?.value;
    final checkin = (existing ?? DailyCheckin(id: _uuid.v4(), date: _todayStr()))
        .copyWith(eveningMood: mood, accomplishment: accomplishment);
    state = const AsyncLoading();
    final saved = await CheckinRepository.instance.upsertCheckin(checkin);
    state = AsyncData(saved);
  }
}

// ── 30-day history ──────────────────────────────────────────────
final checkinHistoryProvider = FutureProvider<List<DailyCheckin>>((ref) async {
  return CheckinRepository.instance.getRecentCheckins(30);
});

// ── Average energy for the past 7 days ─────────────────────────
final avgEnergyProvider = Provider<double>((ref) {
  final history = ref.watch(checkinHistoryProvider).asData?.value ?? [];
  final energyReadings = history
      .where((c) => c.morningEnergy != null)
      .map((c) => c.morningEnergy!)
      .toList();
  if (energyReadings.isEmpty) return 0;
  return energyReadings.reduce((a, b) => a + b) / energyReadings.length;
});
