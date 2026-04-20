import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/goal_models.dart';
import '../data/repositories/goals_repository.dart';

const _goalsUuid = Uuid();

final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() => GoalsRepository.instance.getGoals();

  Future<void> add(Goal goal) async {
    final saved = await GoalsRepository.instance.upsertGoal(goal);
    state = AsyncData([...state.value!, saved]);
  }

  Future<void> upsert(Goal goal) async {
    final saved = await GoalsRepository.instance.upsertGoal(goal);
    state = AsyncData(
        state.value!.map((g) => g.id == saved.id ? saved : g).toList());
  }

  Future<void> delete(String id) async {
    await GoalsRepository.instance.deleteGoal(id);
    state = AsyncData(state.value!.where((g) => g.id != id).toList());
  }

  Future<void> setProgress(String id, int progress) async {
    final goal = state.value!.firstWhere((g) => g.id == id);
    await upsert(goal.copyWith(progress: progress));
  }

  Future<void> setStatus(String id, String status) async {
    final goal = state.value!.firstWhere((g) => g.id == id);
    await upsert(goal.copyWith(status: status));
  }

  Future<void> addSubtask(String goalId, String title) async {
    final goal = state.value!.firstWhere((g) => g.id == goalId);
    final subtask = GoalSubtask(id: _goalsUuid.v4(), title: title);
    await upsert(goal.copyWith(subtasks: [...goal.subtasks, subtask]));
  }

  Future<void> toggleSubtask(String goalId, String subtaskId) async {
    final goal = state.value!.firstWhere((g) => g.id == goalId);
    final updated = goal.subtasks
        .map((s) => s.id == subtaskId ? s.copyWith(done: !s.done) : s)
        .toList();
    await upsert(goal.copyWith(subtasks: updated));
  }

  Future<void> deleteSubtask(String goalId, String subtaskId) async {
    final goal = state.value!.firstWhere((g) => g.id == goalId);
    await upsert(goal.copyWith(
        subtasks: goal.subtasks.where((s) => s.id != subtaskId).toList()));
  }
}
