import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/time_models.dart';
import '../data/models/task_model.dart';
import '../data/repositories/time_repository.dart';

// ── User Tasks ──
final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<UserTask>>(TasksNotifier.new);

class TasksNotifier extends AsyncNotifier<List<UserTask>> {
  @override
  Future<List<UserTask>> build() => TimeRepository.instance.getTasks();

  Future<void> add(UserTask task) async {
    final saved = await TimeRepository.instance.upsertTask(task);
    state = AsyncData([saved, ...(state.value ?? [])]);
  }

  Future<void> updateTask(UserTask task) async {
    final saved = await TimeRepository.instance.upsertTask(task);
    state = AsyncData(
        (state.value ?? []).map((t) => t.id == saved.id ? saved : t).toList());
  }

  Future<void> delete(String id) async {
    await TimeRepository.instance.deleteTask(id);
    state = AsyncData((state.value ?? []).where((t) => t.id != id).toList());
  }

  Future<void> toggleComplete(String id) async {
    final task = (state.value ?? []).firstWhere((t) => t.id == id);
    final updated = task.copyWith(completed: !task.completed);
    final saved = await TimeRepository.instance.upsertTask(updated);
    state = AsyncData((state.value ?? [])
        .map((t) => t.id == id ? saved : t)
        .toList());
  }

  Future<void> reorder(List<UserTask> tasks) async {
    state = AsyncData(tasks);
    await TimeRepository.instance.reorderTasks(tasks);
  }
}

// ── Schedule ──
final scheduleProvider =
    FutureProvider.family<List<ScheduleBlock>, String>((ref, mode) {
  return TimeRepository.instance.getScheduleBlocks(mode);
});

class ScheduleActions {
  ScheduleActions._();
  static final instance = ScheduleActions._();

  Future<void> addBlock(dynamic ref, ScheduleBlock block) async {
    await TimeRepository.instance.upsertBlock(block);
    ref.invalidate(scheduleProvider(block.scheduleMode));
  }

  Future<void> updateBlock(dynamic ref, ScheduleBlock block) async {
    await TimeRepository.instance.upsertBlock(block);
    ref.invalidate(scheduleProvider(block.scheduleMode));
  }

  Future<void> deleteBlock(dynamic ref, String id, String mode) async {
    await TimeRepository.instance.deleteBlock(id);
    ref.invalidate(scheduleProvider(mode));
  }

  Future<void> reorder(dynamic ref, List<ScheduleBlock> reordered, String mode) async {
    await TimeRepository.instance.reorderBlocks(reordered);
    ref.invalidate(scheduleProvider(mode));
  }
}

// ── Calendar ──
final calendarProvider =
    AsyncNotifierProvider<CalendarNotifier, List<CalendarEvent>>(
  CalendarNotifier.new,
);

class CalendarNotifier extends AsyncNotifier<List<CalendarEvent>> {
  @override
  Future<List<CalendarEvent>> build() =>
      TimeRepository.instance.getCalendarEvents(
        from: DateTime(2026, 1, 1),
        to: DateTime(2027, 12, 31),
      );

  Future<void> addEvent(CalendarEvent event) async {
    final saved = await TimeRepository.instance.upsertEvent(event);
    state = AsyncData([...state.value!, saved]);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final saved = await TimeRepository.instance.upsertEvent(event);
    state = AsyncData(
        state.value!.map((e) => e.id == saved.id ? saved : e).toList());
  }

  Future<void> deleteEvent(String id) async {
    await TimeRepository.instance.deleteEvent(id);
    state = AsyncData(state.value!.where((e) => e.id != id).toList());
  }

  Future<void> markDone(String id, bool done) async {
    await TimeRepository.instance.markEventDone(id, done);
    state = AsyncData(
        state.value!.map((e) => e.id == id ? e.copyWith(isDone: done) : e).toList());
  }

  List<CalendarEvent> eventsForDay(DateTime day) {
    return (state.value ?? [])
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }
}
