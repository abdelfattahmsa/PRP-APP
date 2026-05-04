import '../../../../services/supabase_service.dart';
import '../models/health_models.dart';
import '../../providers/fasting_provider.dart';

/// Repository for Health Engine (Habits + Fasting + Body + Nutrition + Exercise).
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

  // ── Body Profile ──
  Future<BodyProfile> getBodyProfile() => _service.getBodyProfile();
  Future<void> upsertBodyProfile(BodyProfile profile) =>
      _service.upsertBodyProfile(profile);

  // ── Weight ──
  Future<List<WeightEntry>> getWeightEntries({int limit = 90}) =>
      _service.getWeightEntries(limit: limit);
  Future<void> addWeightEntry(WeightEntry entry) =>
      _service.addWeightEntry(entry);
  Future<void> deleteWeightEntry(String id) =>
      _service.deleteWeightEntry(id);

  // ── Nutrition ──
  Future<List<CalorieEntry>> getCalorieEntries({int limit = 200}) =>
      _service.getCalorieEntries(limit: limit);
  Future<void> addCalorieEntry(CalorieEntry entry) =>
      _service.addCalorieEntry(entry);
  Future<void> deleteCalorieEntry(String id) =>
      _service.deleteCalorieEntry(id);

  // ── Exercise ──
  Future<List<ExerciseEntry>> getExerciseEntries({int limit = 200}) =>
      _service.getExerciseEntries(limit: limit);
  Future<void> addExerciseEntry(ExerciseEntry entry) =>
      _service.addExerciseEntry(entry);
  Future<void> deleteExerciseEntry(String id) =>
      _service.deleteExerciseEntry(id);
}
