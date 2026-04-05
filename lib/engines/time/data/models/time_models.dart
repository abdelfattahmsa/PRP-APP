import 'package:equatable/equatable.dart';

// ══ SCHEDULE BLOCK ════════════════════════════════════════════════
class ScheduleBlock extends Equatable {
  const ScheduleBlock({
    required this.id,
    required this.scheduleMode,
    required this.time,
    required this.label,
    required this.categoryKey,
    this.duration,
    this.note,
    this.order = 0,
    this.notifyOnStart = true,
    this.notifyOnEnd = false,
  });

  final String id;
  final String scheduleMode; // normal | fasting | friday | cairo
  final String time;         // "04:25"
  final String label;
  final String categoryKey;
  final String? duration;    // "30m", "1hr"
  final String? note;
  final int order;
  final bool notifyOnStart;
  final bool notifyOnEnd;

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) => ScheduleBlock(
        id: json['id'] as String,
        scheduleMode: json['schedule_mode'] as String,
        time: json['time'] as String,
        label: json['label'] as String,
        categoryKey: json['category_key'] as String,
        duration: json['duration'] as String?,
        note: json['note'] as String?,
        order: json['order'] as int? ?? 0,
        notifyOnStart: json['notify_on_start'] as bool? ?? true,
        notifyOnEnd: json['notify_on_end'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_mode': scheduleMode,
        'time': time,
        'label': label,
        'category_key': categoryKey,
        'duration': duration,
        'note': note,
        'order': order,
        'notify_on_start': notifyOnStart,
        'notify_on_end': notifyOnEnd,
      };

  ScheduleBlock copyWith({
    String? time,
    String? label,
    String? categoryKey,
    String? duration,
    String? note,
    int? order,
    bool? notifyOnStart,
    bool? notifyOnEnd,
  }) =>
      ScheduleBlock(
        id: id,
        scheduleMode: scheduleMode,
        time: time ?? this.time,
        label: label ?? this.label,
        categoryKey: categoryKey ?? this.categoryKey,
        duration: duration ?? this.duration,
        note: note ?? this.note,
        order: order ?? this.order,
        notifyOnStart: notifyOnStart ?? this.notifyOnStart,
        notifyOnEnd: notifyOnEnd ?? this.notifyOnEnd,
      );

  /// Parse "04:25" -> minutes since midnight
  int get minutesSinceMidnight {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Parse duration string to minutes
  int get durationMinutes {
    if (duration == null) return 30;
    final s = duration!.toLowerCase();
    int total = 0;
    final hrMatch = RegExp(r'(\d+)\s*h').firstMatch(s);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(s);
    if (hrMatch != null) total += int.parse(hrMatch.group(1)!) * 60;
    if (minMatch != null) total += int.parse(minMatch.group(1)!);
    return total > 0 ? total : 30;
  }

  @override
  List<Object?> get props => [id, scheduleMode, time, label];
}

// ══ CALENDAR EVENT ════════════════════════════════════════════════
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.typeKey,
    this.notes,
    this.linkUrl,
    this.attachmentUrl,
    this.isDone = false,
    this.isDefault = false,
    this.gcalEventId,
    this.createdAt,
  });

  final String id;
  final DateTime date;
  final String title;
  final String typeKey;
  final String? notes;
  final String? linkUrl;
  final String? attachmentUrl;
  final bool isDone;
  final bool isDefault;   // seeded from app defaults
  final String? gcalEventId;
  final DateTime? createdAt;

  String get dateKey =>
      '${date.year}-${date.month}-${date.day}';

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String,
        typeKey: json['type_key'] as String,
        notes: json['notes'] as String?,
        linkUrl: json['link_url'] as String?,
        attachmentUrl: json['attachment_url'] as String?,
        isDone: json['is_done'] as bool? ?? false,
        isDefault: json['is_default'] as bool? ?? false,
        gcalEventId: json['gcal_event_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': dateKey,
        'title': title,
        'type_key': typeKey,
        'notes': notes,
        'link_url': linkUrl,
        'attachment_url': attachmentUrl,
        'is_done': isDone,
        'is_default': isDefault,
        'gcal_event_id': gcalEventId,
      };

  CalendarEvent copyWith({
    String? title,
    String? typeKey,
    String? notes,
    String? linkUrl,
    bool? isDone,
    String? gcalEventId,
  }) =>
      CalendarEvent(
        id: id,
        date: date,
        title: title ?? this.title,
        typeKey: typeKey ?? this.typeKey,
        notes: notes ?? this.notes,
        linkUrl: linkUrl ?? this.linkUrl,
        attachmentUrl: attachmentUrl,
        isDone: isDone ?? this.isDone,
        isDefault: isDefault,
        gcalEventId: gcalEventId ?? this.gcalEventId,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, date, title, typeKey, isDone];
}
