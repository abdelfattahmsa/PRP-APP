import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/supabase_service.dart';

// ══════════════════════════════════════════════════════════════
// FASTING MODEL
// ══════════════════════════════════════════════════════════════

class FastRecord {
  const FastRecord({
    this.id,
    required this.startTime,
    this.endTime,
    required this.goalHours,
  });

  final String? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int goalHours;

  bool get isComplete => endTime != null;

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  bool get goalReached => duration.inMinutes >= goalHours * 60;

  factory FastRecord.fromJson(Map<String, dynamic> j) => FastRecord(
        id: j['id'] as String?,
        startTime: DateTime.parse(j['start_time'] as String),
        endTime: j['end_time'] != null
            ? DateTime.parse(j['end_time'] as String)
            : null,
        goalHours: j['goal_hours'] as int? ?? 16,
      );

  FastRecord copyWith({String? id, DateTime? endTime, int? goalHours}) =>
      FastRecord(
        id: id ?? this.id,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        goalHours: goalHours ?? this.goalHours,
      );
}

class FastingState {
  const FastingState({
    this.active,
    this.goalHours = 16,
    this.history = const [],
  });

  final FastRecord? active;
  final int goalHours;
  final List<FastRecord> history;

  bool get isFasting => active != null;

  Duration get elapsed =>
      active != null ? DateTime.now().difference(active!.startTime) : Duration.zero;

  Duration get remaining {
    if (active == null) return Duration.zero;
    final goal = Duration(hours: active!.goalHours);
    final diff = goal - elapsed;
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progress {
    if (active == null) return 0.0;
    final pct = elapsed.inSeconds / (active!.goalHours * 3600);
    return pct.clamp(0.0, 1.0);
  }

  int get currentStreak {
    if (history.isEmpty) return 0;
    var streak = 0;
    var checkDate = DateTime.now();
    for (var i = history.reversed.toList().length - 1; i >= 0; i--) {
      final rec = history.reversed.toList()[i];
      if (!rec.isComplete || !rec.goalReached) break;
      final recDate = rec.startTime;
      if (recDate.difference(checkDate).inDays.abs() <= 1) {
        streak++;
        checkDate = recDate;
      } else {
        break;
      }
    }
    if (active != null && active!.goalReached) streak++;
    return streak;
  }

  Duration get avgWindow {
    final completed = history.where((r) => r.isComplete).toList();
    if (completed.isEmpty) return Duration.zero;
    final totalMins =
        completed.fold(0, (s, r) => s + r.duration.inMinutes);
    return Duration(minutes: totalMins ~/ completed.length);
  }

  FastRecord? get longestFast {
    if (history.isEmpty) return null;
    return history.reduce((a, b) => a.duration > b.duration ? a : b);
  }

  FastingState copyWith({
    FastRecord? Function()? active,
    int? goalHours,
    List<FastRecord>? history,
  }) =>
      FastingState(
        active: active != null ? active() : this.active,
        goalHours: goalHours ?? this.goalHours,
        history: history ?? this.history,
      );
}

// ══════════════════════════════════════════════════════════════
// NOTIFIER — Supabase-backed, optimistic updates
// ══════════════════════════════════════════════════════════════

class FastingNotifier extends Notifier<FastingState> {
  @override
  FastingState build() {
    _load();
    return const FastingState();
  }

  Future<void> _load() async {
    try {
      final records = await SupabaseService.instance.getFastingRecords();
      FastRecord? active;
      final history = <FastRecord>[];
      for (final r in records) {
        if (r.endTime == null && active == null) {
          active = r;
        } else if (r.endTime != null) {
          history.add(r);
        }
      }
      state = FastingState(
        active: active,
        goalHours: active?.goalHours ?? 16,
        history: history,
      );
    } catch (_) {
      // Not logged in yet or network error — keep default state
    }
  }

  void startFast({int? goalHours}) {
    final goal = goalHours ?? state.goalHours;
    final now = DateTime.now();
    // Optimistic local update
    final optimistic = FastRecord(startTime: now, goalHours: goal);
    state = state.copyWith(active: () => optimistic, goalHours: goal);
    // Persist to Supabase, then update with server-assigned id
    SupabaseService.instance
        .startFastRecord(startTime: now, goalHours: goal)
        .then((saved) {
      state = state.copyWith(active: () => saved);
    }).catchError((_) {
      // Roll back on failure
      state = state.copyWith(active: () => null);
    });
  }

  void stopFast() {
    if (state.active == null) return;
    final activeId = state.active!.id;
    final endTime = DateTime.now();
    final completed = state.active!.copyWith(endTime: endTime);
    state = state.copyWith(
      active: () => null,
      history: [...state.history, completed],
    );
    if (activeId != null) {
      SupabaseService.instance
          .updateFastRecord(activeId, endTime: endTime)
          .catchError((_) {
        // If server fails, we at least have it in local state
      });
    }
  }

  void extendFast(int extraHours) {
    if (state.active == null) return;
    final newGoal = state.active!.goalHours + extraHours;
    final extended = state.active!.copyWith(goalHours: newGoal);
    state = state.copyWith(active: () => extended);
    if (extended.id != null) {
      SupabaseService.instance
          .updateFastRecord(extended.id!, goalHours: newGoal)
          .catchError((_) {});
    }
  }

  void setGoal(int hours) {
    state = state.copyWith(goalHours: hours);
  }
}

final fastingProvider =
    NotifierProvider<FastingNotifier, FastingState>(FastingNotifier.new);

// Live elapsed-second tick
final fastingTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});
