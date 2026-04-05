import '../../../../services/supabase_service.dart';
import '../models/health_models.dart';

/// Repository for Health Engine (Habits).
class HealthRepository {
  HealthRepository._();
  static final instance = HealthRepository._();

  final _service = SupabaseService.instance;

  Future<List<Habit>> getHabits() => _service.getHabits();
  Future<void> upsertHabit(Habit habit) => _service.upsertHabit(habit);
  Future<void> deleteHabit(String id) => _service.deleteHabit(id);
  Future<void> toggleHabitDay(String habitId, String dateKey, bool done) =>
      _service.toggleHabitDay(habitId, dateKey, done);
}
