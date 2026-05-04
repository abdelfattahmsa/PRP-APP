import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

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

// ══ BODY PROFILE ═════════════════════════════════════════════════
class BodyProfile extends Equatable {
  const BodyProfile({
    this.heightCm,
    this.targetWeightKg,
    this.calorieGoal = 2000,
    this.sex,
    this.dateOfBirth,
  });

  final double? heightCm;
  final double? targetWeightKg;
  final int calorieGoal;
  final String? sex; // 'male' | 'female' | 'other'
  final DateTime? dateOfBirth;

  double? calcBmi(double weightKg) {
    if (heightCm == null || heightCm! <= 0) return null;
    final hm = heightCm! / 100;
    return weightKg / (hm * hm);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  static Color bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF42A5F5);
    if (bmi < 25.0) return const Color(0xFF66BB6A);
    if (bmi < 30.0) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  factory BodyProfile.fromJson(Map<String, dynamic> json) => BodyProfile(
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        calorieGoal: (json['calorie_goal'] as num?)?.toInt() ?? 2000,
        sex: json['sex'] as String?,
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.tryParse(json['date_of_birth'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'height_cm': heightCm,
        'target_weight_kg': targetWeightKg,
        'calorie_goal': calorieGoal,
        'sex': sex,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      };

  BodyProfile copyWith({
    double? heightCm,
    double? targetWeightKg,
    int? calorieGoal,
    String? sex,
    DateTime? dateOfBirth,
  }) =>
      BodyProfile(
        heightCm: heightCm ?? this.heightCm,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        calorieGoal: calorieGoal ?? this.calorieGoal,
        sex: sex ?? this.sex,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      );

  @override
  List<Object?> get props => [heightCm, targetWeightKg, calorieGoal, sex, dateOfBirth];
}

// ══ WEIGHT ENTRY ═════════════════════════════════════════════════
class WeightEntry extends Equatable {
  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.note,
  });

  final String id;
  final DateTime date;
  final double weightKg;
  final String? note;

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weight_kg'] as num).toDouble(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T').first,
        'weight_kg': weightKg,
        'note': note,
      };

  WeightEntry copyWith({DateTime? date, double? weightKg, String? note}) =>
      WeightEntry(
        id: id,
        date: date ?? this.date,
        weightKg: weightKg ?? this.weightKg,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [id, date, weightKg];
}

// ══ CALORIE ENTRY ════════════════════════════════════════════════
enum MealType { breakfast, lunch, dinner, snack, drink, other }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch     => 'Lunch',
        MealType.dinner    => 'Dinner',
        MealType.snack     => 'Snack',
        MealType.drink     => 'Drink',
        MealType.other     => 'Other',
      };
  String get icon => switch (this) {
        MealType.breakfast => '🌅',
        MealType.lunch     => '☀️',
        MealType.dinner    => '🌙',
        MealType.snack     => '🍎',
        MealType.drink     => '💧',
        MealType.other     => '🍽️',
      };
}

class CalorieEntry extends Equatable {
  const CalorieEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.description,
    required this.calories,
  });

  final String id;
  final DateTime date;
  final MealType mealType;
  final String description;
  final int calories;

  static MealType _parseMealType(String s) =>
      MealType.values.firstWhere((e) => e.name == s, orElse: () => MealType.other);

  factory CalorieEntry.fromJson(Map<String, dynamic> json) => CalorieEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: _parseMealType(json['meal_type'] as String? ?? 'other'),
        description: json['description'] as String? ?? '',
        calories: (json['calories'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T').first,
        'meal_type': mealType.name,
        'description': description,
        'calories': calories,
      };

  CalorieEntry copyWith({
    MealType? mealType,
    String? description,
    int? calories,
  }) =>
      CalorieEntry(
        id: id,
        date: date,
        mealType: mealType ?? this.mealType,
        description: description ?? this.description,
        calories: calories ?? this.calories,
      );

  @override
  List<Object?> get props => [id, date, mealType, description, calories];
}

// ══ EXERCISE ENTRY ═══════════════════════════════════════════════
enum ExerciseType { cardio, strength, hiit, yoga, sports, other }

extension ExerciseTypeX on ExerciseType {
  String get label => switch (this) {
        ExerciseType.cardio   => 'Cardio',
        ExerciseType.strength => 'Strength',
        ExerciseType.hiit     => 'HIIT',
        ExerciseType.yoga     => 'Yoga',
        ExerciseType.sports   => 'Sports',
        ExerciseType.other    => 'Other',
      };
  String get icon => switch (this) {
        ExerciseType.cardio   => '🏃',
        ExerciseType.strength => '💪',
        ExerciseType.hiit     => '⚡',
        ExerciseType.yoga     => '🧘',
        ExerciseType.sports   => '⚽',
        ExerciseType.other    => '🏋️',
      };
  Color get color => switch (this) {
        ExerciseType.cardio   => const Color(0xFFEF5350),
        ExerciseType.strength => const Color(0xFF42A5F5),
        ExerciseType.hiit     => const Color(0xFFFFA726),
        ExerciseType.yoga     => const Color(0xFF66BB6A),
        ExerciseType.sports   => const Color(0xFFAB47BC),
        ExerciseType.other    => const Color(0xFF78909C),
      };
}

class ExerciseEntry extends Equatable {
  const ExerciseEntry({
    required this.id,
    required this.date,
    required this.name,
    required this.exerciseType,
    this.durationMins = 0,
    this.caloriesBurned = 0,
    this.note,
  });

  final String id;
  final DateTime date;
  final String name;
  final ExerciseType exerciseType;
  final int durationMins;
  final int caloriesBurned;
  final String? note;

  static ExerciseType _parseType(String s) =>
      ExerciseType.values.firstWhere((e) => e.name == s, orElse: () => ExerciseType.other);

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        name: json['name'] as String? ?? '',
        exerciseType: _parseType(json['exercise_type'] as String? ?? 'other'),
        durationMins: (json['duration_mins'] as num?)?.toInt() ?? 0,
        caloriesBurned: (json['calories_burned'] as num?)?.toInt() ?? 0,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T').first,
        'name': name,
        'exercise_type': exerciseType.name,
        'duration_mins': durationMins,
        'calories_burned': caloriesBurned,
        'note': note,
      };

  ExerciseEntry copyWith({
    String? name,
    ExerciseType? exerciseType,
    int? durationMins,
    int? caloriesBurned,
    String? note,
  }) =>
      ExerciseEntry(
        id: id,
        date: date,
        name: name ?? this.name,
        exerciseType: exerciseType ?? this.exerciseType,
        durationMins: durationMins ?? this.durationMins,
        caloriesBurned: caloriesBurned ?? this.caloriesBurned,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [id, date, name, exerciseType, durationMins, caloriesBurned];
}
