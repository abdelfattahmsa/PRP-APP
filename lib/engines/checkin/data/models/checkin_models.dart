// ── Daily Check-in model ────────────────────────────────────────
class DailyCheckin {
  const DailyCheckin({
    required this.id,
    required this.date,
    this.morningEnergy,
    this.topPriority,
    this.eveningMood,
    this.accomplishment,
    // ── 4-resource extensions ──
    this.morningMoneyNote,
    this.morningTimeNote,
    this.morningHealthNote,
    this.eveningMoneyNote,
    this.eveningTimeNote,
    this.eveningHealthNote,
  });

  final String id;
  final String date; // 'YYYY-MM-DD'

  // Energy pillar
  final int? morningEnergy;    // 1–5
  final String? topPriority;
  final int? eveningMood;      // 1–5
  final String? accomplishment;

  // Money, Time, Health notes (morning)
  final String? morningMoneyNote;
  final String? morningTimeNote;
  final String? morningHealthNote;

  // Money, Time, Health notes (evening)
  final String? eveningMoneyNote;
  final String? eveningTimeNote;
  final String? eveningHealthNote;

  bool get hasMorning => morningEnergy != null;
  bool get hasEvening => eveningMood != null;

  factory DailyCheckin.fromJson(Map<String, dynamic> j) => DailyCheckin(
        id: j['id'] as String,
        date: j['date'] as String,
        morningEnergy: j['morning_energy'] as int?,
        topPriority: j['top_priority'] as String?,
        eveningMood: j['evening_mood'] as int?,
        accomplishment: j['accomplishment'] as String?,
        morningMoneyNote: j['morning_money_note'] as String?,
        morningTimeNote: j['morning_time_note'] as String?,
        morningHealthNote: j['morning_health_note'] as String?,
        eveningMoneyNote: j['evening_money_note'] as String?,
        eveningTimeNote: j['evening_time_note'] as String?,
        eveningHealthNote: j['evening_health_note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        if (morningEnergy != null) 'morning_energy': morningEnergy,
        if (topPriority != null) 'top_priority': topPriority,
        if (eveningMood != null) 'evening_mood': eveningMood,
        if (accomplishment != null) 'accomplishment': accomplishment,
        if (morningMoneyNote != null) 'morning_money_note': morningMoneyNote,
        if (morningTimeNote != null) 'morning_time_note': morningTimeNote,
        if (morningHealthNote != null) 'morning_health_note': morningHealthNote,
        if (eveningMoneyNote != null) 'evening_money_note': eveningMoneyNote,
        if (eveningTimeNote != null) 'evening_time_note': eveningTimeNote,
        if (eveningHealthNote != null) 'evening_health_note': eveningHealthNote,
      };

  DailyCheckin copyWith({
    int? morningEnergy,
    String? topPriority,
    int? eveningMood,
    String? accomplishment,
    String? morningMoneyNote,
    String? morningTimeNote,
    String? morningHealthNote,
    String? eveningMoneyNote,
    String? eveningTimeNote,
    String? eveningHealthNote,
  }) =>
      DailyCheckin(
        id: id,
        date: date,
        morningEnergy: morningEnergy ?? this.morningEnergy,
        topPriority: topPriority ?? this.topPriority,
        eveningMood: eveningMood ?? this.eveningMood,
        accomplishment: accomplishment ?? this.accomplishment,
        morningMoneyNote: morningMoneyNote ?? this.morningMoneyNote,
        morningTimeNote: morningTimeNote ?? this.morningTimeNote,
        morningHealthNote: morningHealthNote ?? this.morningHealthNote,
        eveningMoneyNote: eveningMoneyNote ?? this.eveningMoneyNote,
        eveningTimeNote: eveningTimeNote ?? this.eveningTimeNote,
        eveningHealthNote: eveningHealthNote ?? this.eveningHealthNote,
      );
}

// Energy / mood labels
const kEnergyEmojis  = ['😴', '😑', '😐', '😊', '🔥'];
const kEnergyLabels  = ['Exhausted', 'Low', 'Okay', 'Good', 'On fire'];
const kMoodEmojis    = ['😞', '😕', '😐', '🙂', '😄'];
const kMoodLabels    = ['Rough', 'Below average', 'Average', 'Good', 'Great'];
