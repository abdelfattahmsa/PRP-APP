import '../../../../services/supabase_service.dart';
import '../models/goal_models.dart';

/// Repository for Goals Engine.
class GoalsRepository {
  GoalsRepository._();
  static final instance = GoalsRepository._();

  final _service = SupabaseService.instance;

  Future<List<Goal>> getGoals() => _service.getGoals();
  Future<Goal> upsertGoal(Goal goal) => _service.upsertGoal(goal);
  Future<void> deleteGoal(String id) => _service.deleteGoal(id);
}
