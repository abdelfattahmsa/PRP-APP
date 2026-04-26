// ── Daily Check-in model ────────────────────────────────────────
class DailyCheckin {
  const DailyCheckin({
    required this.id,
    required this.date,
    this.morningEnergy,
    this.topPriority,
    this.eveningMood,
    this.accomplishment,
  });

  final String id;
  final String date; // 'YYYY-MM-DD'
  final int? morningEnergy;    // 1–5
  final String? topPriority;
  final int? eveningMood;      // 1–5
  final String? accomplishment;

  bool get hasMorning => morningEnergy != null;
  bool get hasEvening => eveningMood != null;

  factory DailyCheckin.fromJson(Map<String, dynamic> j) => DailyCheckin(
        id: j['id'] as String,
        date: j['date'] as String,
        morningEnergy: j['morning_energy'] as int?,
        topPriority: j['top_priority'] as String?,
        eveningMood: j['evening_mood'] as int?,
        accomplishment: j['accomplishment'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        if (morningEnergy != null) 'morning_energy': morningEnergy,
        if (topPriority != null) 'top_priority': topPriority,
        if (eveningMood != null) 'evening_mood': eveningMood,
        if (accomplishment != null) 'accomplishment': accomplishment,
      };

  DailyCheckin copyWith({
    int? morningEnergy,
    String? topPriority,
    int? eveningMood,
    String? accomplishment,
  }) =>
      DailyCheckin(
        id: id,
        date: date,
        morningEnergy: morningEnergy ?? this.morningEnergy,
        topPriority: topPriority ?? this.topPriority,
        eveningMood: eveningMood ?? this.eveningMood,
        accomplishment: accomplishment ?? this.accomplishment,
      );
}

// Energy / mood labels
const kEnergyEmojis  = ['😴', '😑', '😐', '😊', '🔥'];
const kEnergyLabels  = ['Exhausted', 'Low', 'Okay', 'Good', 'On fire'];
const kMoodEmojis    = ['😞', '😕', '😐', '🙂', '😄'];
const kMoodLabels    = ['Rough', 'Below average', 'Average', 'Good', 'Great'];
