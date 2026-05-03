import 'package:equatable/equatable.dart';

// ══ MOOD ENTRY ════════════════════════════════════════════════════
/// A single mood log: level 1–5, period morning | evening.
class MoodEntry extends Equatable {
  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.period,
    this.note,
  });

  final String id;
  final DateTime timestamp;
  /// 1 = Terrible … 5 = Excellent
  final int level;
  /// 'morning' | 'evening'
  final String period;
  final String? note;

  static const emojis  = ['😞', '😕', '😐', '🙂', '😁'];
  static const labels  = ['Terrible', 'Bad', 'Okay', 'Good', 'Excellent'];
  static const colors  = [0xFFE53935, 0xFFFF7043, 0xFFFDD835, 0xFF66BB6A, 0xFF26C6DA];

  String get emoji => level >= 1 && level <= 5 ? emojis[level - 1] : '😐';
  String get label => level >= 1 && level <= 5 ? labels[level - 1] : 'Okay';
  int    get colorValue => level >= 1 && level <= 5 ? colors[level - 1] : 0xFFFDD835;

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        level: (j['level'] as num).toInt(),
        period: j['period'] as String,
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'period': period,
        if (note != null) 'note': note,
      };

  MoodEntry copyWith({int? level, String? note, bool clearNote = false}) =>
      MoodEntry(
        id: id,
        timestamp: timestamp,
        level: level ?? this.level,
        period: period,
        note: clearNote ? null : (note ?? this.note),
      );

  @override
  List<Object?> get props => [id, timestamp, level, period];
}

// ══ PLANNED SESSION ══════════════════════════════════════════════
/// Represents one planned focus session in the queue (for a task or free block).
class PlannedSession extends Equatable {
  const PlannedSession({
    required this.id,
    required this.label,
    required this.categoryKey,
    this.taskId,
    this.durationMinutes = 25,
  });

  final String id;
  final String label;          // task title or custom label
  final String categoryKey;
  final String? taskId;        // null for free-form blocks
  final int durationMinutes;

  PlannedSession copyWith({
    String? label,
    String? categoryKey,
    int? durationMinutes,
  }) =>
      PlannedSession(
        id: id,
        label: label ?? this.label,
        categoryKey: categoryKey ?? this.categoryKey,
        taskId: taskId,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );

  @override
  List<Object?> get props => [id, label, durationMinutes];
}

// ══ FOCUS QUEUE STATE ════════════════════════════════════════════
class FocusQueueState {
  const FocusQueueState({
    this.sessions = const [],
    this.currentIndex = 0,
    this.autoAdvance = true,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  final List<PlannedSession> sessions;
  final int currentIndex;      // index into `sessions`
  final bool autoAdvance;      // auto-start next session after break
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;

  bool get isEmpty => sessions.isEmpty;
  bool get hasNext => currentIndex < sessions.length - 1;
  PlannedSession? get current =>
      sessions.isEmpty ? null : sessions[currentIndex];

  int breakMinutesAfter(int index) {
    // long break every N sessions, otherwise short break
    if ((index + 1) % sessionsBeforeLongBreak == 0) return longBreakMinutes;
    return shortBreakMinutes;
  }

  FocusQueueState copyWith({
    List<PlannedSession>? sessions,
    int? currentIndex,
    bool? autoAdvance,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) =>
      FocusQueueState(
        sessions: sessions ?? this.sessions,
        currentIndex: currentIndex ?? this.currentIndex,
        autoAdvance: autoAdvance ?? this.autoAdvance,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        sessionsBeforeLongBreak:
            sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      );
}

// ══ FOCUS SESSION ════════════════════════════════════════════════
class FocusSession extends Equatable {
  const FocusSession({
    required this.id,
    required this.date,
    required this.blockLabel,
    required this.blockCategoryKey,
    required this.plannedSeconds,
    required this.actualSeconds,
    required this.completed,
    this.note,
    this.startedAt,
  });

  final String id;
  final DateTime date;
  final String blockLabel;
  final String blockCategoryKey;
  final int plannedSeconds;
  final int actualSeconds;
  final bool completed;
  final String? note;
  final DateTime? startedAt;

  int get actualMinutes => (actualSeconds / 60).round();
  int get plannedMinutes => (plannedSeconds / 60).round();
  double get completionRate =>
      plannedSeconds > 0 ? actualSeconds / plannedSeconds : 0;

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        date: DateTime.parse((json['date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()) as String),
        blockLabel: json['block_label'] as String? ?? json['mode'] as String? ?? 'Focus',
        blockCategoryKey: json['block_category_key'] as String? ?? 'rest',
        plannedSeconds: json['planned_seconds'] as int? ??
            ((json['duration'] as num?)?.toInt() ?? 1500),
        actualSeconds: json['actual_seconds'] as int? ??
            ((json['duration'] as num?)?.toInt() ?? 0),
        completed: json['completed'] as bool? ?? true,
        note: json['note'] as String?,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T').first,
        'block_label': blockLabel,
        'block_category_key': blockCategoryKey,
        'planned_seconds': plannedSeconds,
        'actual_seconds': actualSeconds,
        'completed': completed,
        'note': note,
        'started_at': startedAt?.toIso8601String(),
      };

  FocusSession copyWith({
    String? blockLabel,
    String? blockCategoryKey,
    String? note,
    bool clearNote = false,
  }) =>
      FocusSession(
        id: id,
        date: date,
        blockLabel: blockLabel ?? this.blockLabel,
        blockCategoryKey: blockCategoryKey ?? this.blockCategoryKey,
        plannedSeconds: plannedSeconds,
        actualSeconds: actualSeconds,
        completed: completed,
        note: clearNote ? null : (note ?? this.note),
        startedAt: startedAt,
      );

  @override
  List<Object?> get props => [id, date, blockLabel, completed];
}

// ══ FOCUS TIMER STATE ════════════════════════════════════════════
class FocusTimerState {
  const FocusTimerState({
    this.secondsLeft = 25 * 60,
    this.isRunning = false,
    this.mode = 'focus',
    this.focusDuration = 25,
    this.breakDuration = 5,
    this.selectedBlockLabel = '',
    this.selectedBlockCategory = 'rest',
    this.note = '',
    this.startedAt,
    this.previouslyElapsedSeconds = 0,
    this.completedAt,
  });

  final int secondsLeft;
  final bool isRunning;
  final String mode;
  final int focusDuration;
  final int breakDuration;
  final String selectedBlockLabel;
  final String selectedBlockCategory;
  final String note;
  final DateTime? startedAt;
  final int previouslyElapsedSeconds;
  /// Set when session completes; cleared on reset. Shell listener uses this.
  final DateTime? completedAt;

  int get totalSeconds =>
      (mode == 'focus' ? focusDuration : breakDuration) * 60;
  double get progress =>
      totalSeconds > 0 ? 1.0 - (secondsLeft / totalSeconds) : 0.0;

  FocusTimerState copyWith({
    int? secondsLeft, bool? isRunning, String? mode,
    int? focusDuration, int? breakDuration,
    String? selectedBlockLabel, String? selectedBlockCategory,
    String? note, DateTime? startedAt, bool clearStartedAt = false,
    int? previouslyElapsedSeconds,
    DateTime? completedAt, bool clearCompletedAt = false,
  }) =>
      FocusTimerState(
        secondsLeft: secondsLeft ?? this.secondsLeft,
        isRunning: isRunning ?? this.isRunning,
        mode: mode ?? this.mode,
        focusDuration: focusDuration ?? this.focusDuration,
        breakDuration: breakDuration ?? this.breakDuration,
        selectedBlockLabel: selectedBlockLabel ?? this.selectedBlockLabel,
        selectedBlockCategory: selectedBlockCategory ?? this.selectedBlockCategory,
        note: note ?? this.note,
        startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
        previouslyElapsedSeconds:
            previouslyElapsedSeconds ?? this.previouslyElapsedSeconds,
        completedAt:
            clearCompletedAt ? null : (completedAt ?? this.completedAt),
      );
}
