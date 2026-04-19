import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════
// FASTING MODEL
// ══════════════════════════════════════════════════════════════

class FastRecord {
  const FastRecord({
    required this.startTime,
    this.endTime,
    required this.goalHours,
  });

  final DateTime startTime;
  final DateTime? endTime;
  final int goalHours;

  bool get isComplete => endTime != null;

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  bool get goalReached => duration.inMinutes >= goalHours * 60;

  Map<String, dynamic> toJson() => {
        'start': startTime.toIso8601String(),
        'end': endTime?.toIso8601String(),
        'goal': goalHours,
      };

  factory FastRecord.fromJson(Map<String, dynamic> j) => FastRecord(
        startTime: DateTime.parse(j['start'] as String),
        endTime: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
        goalHours: j['goal'] as int? ?? 16,
      );
}

class FastingState {
  const FastingState({
    this.active,
    this.goalHours = 16,
    this.history = const [],
  });

  final FastRecord? active; // null → not currently fasting
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
    // also count active fast if goal reached
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
// NOTIFIER
// ══════════════════════════════════════════════════════════════

const _kPrefActive = 'fasting_active';
const _kPrefHistory = 'fasting_history';
const _kPrefGoal = 'fasting_goal';

class FastingNotifier extends Notifier<FastingState> {
  @override
  FastingState build() {
    _load();
    return const FastingState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final activeJson = prefs.getString(_kPrefActive);
    final historyJson = prefs.getStringList(_kPrefHistory) ?? [];
    final goal = prefs.getInt(_kPrefGoal) ?? 16;

    FastRecord? active;
    if (activeJson != null) {
      try {
        active = FastRecord.fromJson(jsonDecode(activeJson));
      } catch (_) {}
    }

    final history = historyJson
        .map((s) {
          try {
            return FastRecord.fromJson(jsonDecode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<FastRecord>()
        .toList();

    state = FastingState(active: active, goalHours: goal, history: history);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.active != null) {
      await prefs.setString(_kPrefActive, jsonEncode(state.active!.toJson()));
    } else {
      await prefs.remove(_kPrefActive);
    }
    await prefs.setStringList(
      _kPrefHistory,
      state.history.map((r) => jsonEncode(r.toJson())).toList(),
    );
    await prefs.setInt(_kPrefGoal, state.goalHours);
  }

  void startFast({int? goalHours}) {
    final goal = goalHours ?? state.goalHours;
    final record = FastRecord(startTime: DateTime.now(), goalHours: goal);
    state = state.copyWith(active: () => record, goalHours: goal);
    _save();
  }

  void stopFast() {
    if (state.active == null) return;
    final completed = FastRecord(
      startTime: state.active!.startTime,
      endTime: DateTime.now(),
      goalHours: state.active!.goalHours,
    );
    state = state.copyWith(
      active: () => null,
      history: [...state.history, completed],
    );
    _save();
  }

  void extendFast(int extraHours) {
    if (state.active == null) return;
    final newGoal = state.active!.goalHours + extraHours;
    final extended = FastRecord(
      startTime: state.active!.startTime,
      goalHours: newGoal,
    );
    state = state.copyWith(active: () => extended);
    _save();
  }

  void setGoal(int hours) {
    state = state.copyWith(goalHours: hours);
    _save();
  }
}

final fastingProvider =
    NotifierProvider<FastingNotifier, FastingState>(FastingNotifier.new);

// Live elapsed-second tick
final fastingTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});
