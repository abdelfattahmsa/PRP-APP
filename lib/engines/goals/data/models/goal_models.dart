import 'package:equatable/equatable.dart';

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
        linkedCalendarEventIds: linkedCalendarEventIds,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, targetDate, status, progress];
}
