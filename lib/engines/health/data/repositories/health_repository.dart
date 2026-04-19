import '../../../../services/supabase_service.dart';
import '../models/health_models.dart';
import '../../providers/fasting_provider.dart';

/// Repository for Health Engine (Habits + Fasting).
class HealthRepository {
  HealthRepository._();
  static final instance = HealthRepository._();

  final _service = SupabaseService.instance;

  // ── Habits ──
  Future<List<Habit>> getHabits() => _service.getHabits();
  Future<void> upsertHabit(Habit habit) => _service.upsertHabit(habit);
  Future<void> deleteHabit(String id) => _service.deleteHabit(id);
  Future<void> toggleHabitDay(String habitId, String dateKey, bool done) =>
      _service.toggleHabitDay(habitId, dateKey, done);

  // ── Fasting ──
  Future<List<FastRecord>> getFastingRecords() =>
      _service.getFastingRecords();
  Future<FastRecord> startFastRecord({
    required DateTime startTime,
    required int goalHours,
  }) =>
      _service.startFastRecord(startTime: startTime, goalHours: goalHours);
  Future<void> updateFastRecord(String id,
          {DateTime? endTime, int? goalHours}) =>
      _service.updateFastRecord(id, endTime: endTime, goalHours: goalHours);
}
