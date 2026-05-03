import 'package:equatable/equatable.dart';

// ══ USER TASK ════════════════════════════════════════════════���═══
/// A manually-added task with a duration, optional due date, and category.
class UserTask extends Equatable {
  const UserTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.categoryKey,
    required this.durationMinutes,
    this.dueDate,
    this.completed = false,
    this.order = 0,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String categoryKey;
  final int durationMinutes;
  final DateTime? dueDate;
  final bool completed;
  final int order;
  final DateTime? createdAt;

  bool get isOverdue =>
      !completed &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now().copyWith(hour: 0, minute: 0, second: 0));

  factory UserTask.fromJson(Map<String, dynamic> j) => UserTask(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        title: j['title'] as String,
        categoryKey: j['category_key'] as String? ?? 'work',
        durationMinutes: j['duration_minutes'] as int? ?? 30,
        dueDate: j['due_date'] != null
            ? DateTime.parse(j['due_date'] as String)
            : null,
        completed: j['completed'] as bool? ?? false,
        order: j['order'] as int? ?? 0,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category_key': categoryKey,
        'duration_minutes': durationMinutes,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'completed': completed,
        'order': order,
      };

  UserTask copyWith({
    String? title,
    String? categoryKey,
    int? durationMinutes,
    DateTime? dueDate,
    bool? completed,
    int? order,
    bool clearDueDate = false,
  }) =>
      UserTask(
        id: id,
        userId: userId,
        title: title ?? this.title,
        categoryKey: categoryKey ?? this.categoryKey,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        completed: completed ?? this.completed,
        order: order ?? this.order,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, completed, dueDate];
}
