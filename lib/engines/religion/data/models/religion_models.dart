import 'package:equatable/equatable.dart';

// ── Prayer constants ──────────────────────────────────────────
const kPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const kPrayerLabels = {
  'fajr':    'Fajr',
  'dhuhr':   'Dhuhr',
  'asr':     'Asr',
  'maghrib': 'Maghrib',
  'isha':    'Isha',
};

const kPrayerEmojis = {
  'fajr':    '🌅',
  'dhuhr':   '☀️',
  'asr':     '🌤️',
  'maghrib': '🌆',
  'isha':    '🌙',
};

// ── SALAH RECORD ─────────────────────────────────────────────
/// Stores the completion state of all 5 daily prayers for one day.
class SalahRecord extends Equatable {
  const SalahRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.prayers,
  });

  final String id;
  final String userId;
  final String date; // 'YYYY-MM-DD'

  /// Map of prayer key → done (true) | missed (false) | not logged (absent)
  final Map<String, bool?> prayers;

  int get completedCount => kPrayerKeys.where((k) => prayers[k] == true).length;
  int get missedCount => kPrayerKeys.where((k) => prayers[k] == false).length;
  bool get isFullDay => completedCount == 5;
  bool isPrayer(String key) => prayers[key] == true;

  SalahRecord copyWithPrayer(String key, bool done) {
    final updated = Map<String, bool?>.from(prayers);
    updated[key] = done;
    return SalahRecord(id: id, userId: userId, date: date, prayers: updated);
  }

  factory SalahRecord.forToday(String userId) {
    final today = DateTime.now();
    final dateStr = '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return SalahRecord(
      id: '',
      userId: userId,
      date: dateStr,
      prayers: {},
    );
  }

  factory SalahRecord.fromJson(Map<String, dynamic> json) {
    final rawPrayers = json['prayers'] as Map<String, dynamic>? ?? {};
    return SalahRecord(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      date: (json['date'] as String).substring(0, 10),
      prayers: rawPrayers.map((k, v) => MapEntry(k, v as bool?)),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.isEmpty ? null : id,
        'user_id': userId,
        'date': date,
        'prayers': prayers,
      };

  @override
  List<Object?> get props => [id, date, prayers];
}

// ── QURAN SESSION ────────────────────────────────────────────
class QuranSession extends Equatable {
  const QuranSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.minutes,
    required this.type,
    this.fromSurah,
    this.toSurah,
    this.notes,
  });

  final String id;
  final String userId;
  final String date; // 'YYYY-MM-DD'
  final int minutes;
  final String type; // 'reading' | 'memorization' | 'revision'
  final int? fromSurah;
  final int? toSurah;
  final String? notes;

  factory QuranSession.fromJson(Map<String, dynamic> json) => QuranSession(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: (json['date'] as String).substring(0, 10),
        minutes: json['minutes'] as int? ?? 15,
        type: json['type'] as String? ?? 'reading',
        fromSurah: json['from_surah'] as int?,
        toSurah: json['to_surah'] as int?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'date': date,
        'minutes': minutes,
        'type': type,
        if (fromSurah != null) 'from_surah': fromSurah,
        if (toSurah != null) 'to_surah': toSurah,
        if (notes != null) 'notes': notes,
      };

  @override
  List<Object?> get props => [id, date, minutes, type];
}

// ── Surah names (1–114) ──────────────────────────────────────
const kSurahNames = [
  '', // index 0 placeholder
  'Al-Fatihah', 'Al-Baqarah', 'Ali \'Imran', 'An-Nisa\'', 'Al-Ma\'idah',
  'Al-An\'am', 'Al-A\'raf', 'Al-Anfal', 'At-Tawbah', 'Yunus',
  'Hud', 'Yusuf', 'Ar-Ra\'d', 'Ibrahim', 'Al-Hijr',
  'An-Nahl', 'Al-Isra\'', 'Al-Kahf', 'Maryam', 'Ta-Ha',
  'Al-Anbya\'', 'Al-Hajj', 'Al-Mu\'minun', 'An-Nur', 'Al-Furqan',
  'Ash-Shu\'ara\'', 'An-Naml', 'Al-Qasas', 'Al-\'Ankabut', 'Ar-Rum',
  'Luqman', 'As-Sajdah', 'Al-Ahzab', 'Saba\'', 'Fatir',
  'Ya-Sin', 'As-Saffat', 'Sad', 'Az-Zumar', 'Ghafir',
  'Fussilat', 'Ash-Shura', 'Az-Zukhruf', 'Ad-Dukhan', 'Al-Jathiyah',
  'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf',
  'Adh-Dhariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman',
  'Al-Waqi\'ah', 'Al-Hadid', 'Al-Mujadila', 'Al-Hashr', 'Al-Mumtahanah',
  'As-Saf', 'Al-Jumu\'ah', 'Al-Munafiqun', 'At-Taghabun', 'At-Talaq',
  'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', 'Al-Ma\'arij',
  'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddaththir', 'Al-Qiyamah',
  'Al-Insan', 'Al-Mursalat', 'An-Naba\'', 'An-Nazi\'at', '\'Abasa',
  'At-Takwir', 'Al-Infitar', 'Al-Mutaffifin', 'Al-Inshiqaq', 'Al-Buruj',
  'At-Tariq', 'Al-A\'la', 'Al-Ghashiyah', 'Al-Fajr', 'Al-Balad',
  'Ash-Shams', 'Al-Layl', 'Ad-Duha', 'Ash-Sharh', 'At-Tin',
  'Al-\'Alaq', 'Al-Qadr', 'Al-Bayyinah', 'Az-Zalzalah', 'Al-\'Adiyat',
  'Al-Qari\'ah', 'At-Takathur', 'Al-\'Asr', 'Al-Humazah', 'Al-Fil',
  'Quraysh', 'Al-Ma\'un', 'Al-Kawthar', 'Al-Kafirun', 'An-Nasr',
  'Al-Masad', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas',
];
