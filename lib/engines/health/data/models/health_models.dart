import 'package:equatable/equatable.dart';

// ══ HABIT ════════════════════════════════════════════════════════
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.streak = 0,
    this.longestStreak = 0,
    this.history = const {},
    this.order = 0,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String icon;
  final int streak;
  final int longestStreak;
  final Map<String, bool> history; // 'YYYY-MM-DD' -> done
  final int order;
  final bool isArchived;

  bool isDoneOn(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return history[key] ?? false;
  }

  bool get isDoneToday => isDoneOn(DateTime.now());

  int calculateStreak() {
    var s = 0;
    var d = DateTime.now();
    while (true) {
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (history[k] != true) break;
      s++;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        streak: json['streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        history: Map<String, bool>.from(json['history'] as Map? ?? {}),
        order: json['order'] as int? ?? 0,
        isArchived: json['is_archived'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'streak': streak,
        'longest_streak': longestStreak,
        'history': history,
        'order': order,
        'is_archived': isArchived,
      };

  Habit copyWith({
    String? name,
    String? icon,
    int? streak,
    int? longestStreak,
    Map<String, bool>? history,
    int? order,
    bool? isArchived,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        streak: streak ?? this.streak,
        longestStreak: longestStreak ?? this.longestStreak,
        history: history ?? this.history,
        order: order ?? this.order,
        isArchived: isArchived ?? this.isArchived,
      );

  @override
  List<Object?> get props => [id, name, streak];
}
