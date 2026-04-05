import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/health_models.dart';
import '../data/repositories/health_repository.dart';

final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() => HealthRepository.instance.getHabits();

  Future<void> add(Habit habit) async {
    await HealthRepository.instance.upsertHabit(habit);
    state = AsyncData([...state.value!, habit]);
  }

  Future<void> upsert(Habit habit) async {
    await HealthRepository.instance.upsertHabit(habit);
    state = AsyncData(
        state.value!.map((h) => h.id == habit.id ? habit : h).toList());
  }

  Future<void> delete(String id) async {
    await HealthRepository.instance.deleteHabit(id);
    state = AsyncData(state.value!.where((h) => h.id != id).toList());
  }

  Future<void> toggle(String id, String dateKey) async {
    final habits = state.value!;
    final habit = habits.firstWhere((h) => h.id == id);
    final wasDone = habit.history[dateKey] ?? false;
    await HealthRepository.instance.toggleHabitDay(id, dateKey, !wasDone);
    final newHistory = Map<String, bool>.from(habit.history);
    newHistory[dateKey] = !wasDone;
    final updated = habit.copyWith(history: newHistory);
    final newStreak = updated.calculateStreak();
    final withStreak = updated.copyWith(
      streak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    );
    state = AsyncData(habits.map((h) => h.id == id ? withStreak : h).toList());
  }
}

// Derived: today's completion %
final habitsTodayProvider = Provider((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  if (habits.isEmpty) return (done: 0, total: 0, pct: 0.0);
  final done = habits.where((h) => h.isDoneToday).length;
  return (done: done, total: habits.length, pct: done / habits.length);
});
