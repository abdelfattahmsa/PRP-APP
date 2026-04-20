import 'package:equatable/equatable.dart';

// ══ GOAL SUBTASK ══════════════════════════════════════════════════
class GoalSubtask {
  const GoalSubtask({
    required this.id,
    required this.title,
    this.done = false,
  });

  final String id;
  final String title;
  final bool done;

  factory GoalSubtask.fromJson(Map<String, dynamic> j) => GoalSubtask(
        id: j['id'] as String,
        title: j['title'] as String,
        done: j['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  GoalSubtask copyWith({String? title, bool? done}) =>
      GoalSubtask(id: id, title: title ?? this.title, done: done ?? this.done);
}

// ══ GOAL ══════════════════════════════════════════════════════════
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.title,
    required this.targetDate,
    this.description,
    this.priority = 'medium',
    this.status = 'active',
    this.progress = 0,
    this.milestones = const [],
    this.subtasks = const [],
    this.linkedCalendarEventIds = const [],
    this.createdAt,
  });

  final String id;
  final String title;
  final DateTime targetDate;
  final String? description;
  final String priority;    // high | medium | low
  final String status;      // active | done | paused
  final int progress;       // 0-100
  final List<String> milestones;
  final List<GoalSubtask> subtasks;
  final List<String> linkedCalendarEventIds;
  final DateTime? createdAt;

  int get daysRemaining =>
      targetDate.difference(DateTime.now()).inDays;

  bool get isOverdue => daysRemaining < 0 && status == 'active';
  bool get isDueSoon => daysRemaining >= 0 && daysRemaining <= 14;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        targetDate: DateTime.parse(json['target_date'] as String),
        description: json['description'] as String?,
        priority: json['priority'] as String? ?? 'medium',
        status: json['status'] as String? ?? 'active',
        progress: json['progress'] as int? ?? 0,
        milestones: List<String>.from(json['milestones'] as List? ?? []),
        subtasks: (json['subtasks'] as List? ?? [])
            .map((s) => GoalSubtask.fromJson(s as Map<String, dynamic>))
            .toList(),
        linkedCalendarEventIds:
            List<String>.from(json['linked_event_ids'] as List? ?? []),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target_date': targetDate.toIso8601String().split('T').first,
        'description': description,
        'priority': priority,
        'status': status,
        'progress': progress,
        'milestones': milestones,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'linked_event_ids': linkedCalendarEventIds,
      };

  Goal copyWith({
    String? title,
    DateTime? targetDate,
    String? description,
    String? priority,
    String? status,
    int? progress,
    List<String>? milestones,
    List<GoalSubtask>? subtasks,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        targetDate: targetDate ?? this.targetDate,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        milestones: milestones ?? this.milestones,
        subtasks: subtasks ?? this.subtasks,
        linkedCalendarEventIds: linkedCalendarEventIds,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, targetDate, status, progress];
}
