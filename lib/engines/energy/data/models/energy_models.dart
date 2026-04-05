import 'package:equatable/equatable.dart';

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
        date: DateTime.parse(json['date'] as String),
        blockLabel: json['block_label'] as String,
        blockCategoryKey: json['block_category_key'] as String,
        plannedSeconds: json['planned_seconds'] as int,
        actualSeconds: json['actual_seconds'] as int,
        completed: json['completed'] as bool,
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

  int get totalSeconds =>
      (mode == 'focus' ? focusDuration : breakDuration) * 60;
  double get progress => 1.0 - (secondsLeft / totalSeconds);

  FocusTimerState copyWith({
    int? secondsLeft, bool? isRunning, String? mode,
    int? focusDuration, int? breakDuration,
    String? selectedBlockLabel, String? selectedBlockCategory,
    String? note, DateTime? startedAt,
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
        startedAt: startedAt ?? this.startedAt,
      );
}
