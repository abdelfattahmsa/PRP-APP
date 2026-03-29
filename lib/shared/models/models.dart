/// ─── DATA MODELS ────────────────────────────────────────────────
/// All models in one file for clarity. In a larger app these
/// would be split into separate files per feature.

import 'package:equatable/equatable.dart';

// ══ USER ═════════════════════════════════════════════════════════
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
      };

  AppUser copyWith({String? fullName, String? avatarUrl}) => AppUser(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, email, fullName];
}

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

  /// Parse "04:25" → minutes since midnight
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

// ══ BANK ACCOUNT ══════════════════════════════════════════════════
class BankAccount extends Equatable {
  const BankAccount({
    required this.id,
    required this.name,
    this.creditCardBalance = 0,
    this.creditCardLimit = 0,
    this.savingsBalance = 0,
    this.currentBalance = 0,
    this.order = 0,
  });

  final String id;
  final String name;
  final double creditCardBalance;
  final double creditCardLimit;
  final double savingsBalance;
  final double currentBalance;
  final int order;

  double get remainingCreditLimit => creditCardLimit - creditCardBalance;
  bool get isOverLimit => remainingCreditLimit < 0;

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        creditCardBalance: (json['cc_balance'] as num?)?.toDouble() ?? 0,
        creditCardLimit: (json['cc_limit'] as num?)?.toDouble() ?? 0,
        savingsBalance: (json['savings_balance'] as num?)?.toDouble() ?? 0,
        currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
        order: json['order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cc_balance': creditCardBalance,
        'cc_limit': creditCardLimit,
        'savings_balance': savingsBalance,
        'current_balance': currentBalance,
        'order': order,
      };

  BankAccount copyWith({
    String? name,
    double? creditCardBalance,
    double? creditCardLimit,
    double? savingsBalance,
    double? currentBalance,
  }) =>
      BankAccount(
        id: id,
        name: name ?? this.name,
        creditCardBalance: creditCardBalance ?? this.creditCardBalance,
        creditCardLimit: creditCardLimit ?? this.creditCardLimit,
        savingsBalance: savingsBalance ?? this.savingsBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        order: order,
      );

  @override
  List<Object?> get props => [id, name];
}

// ══ EXTERNAL DEBT ════════════════════════════════════════════════
class ExternalDebt extends Equatable {
  const ExternalDebt({
    required this.id,
    required this.source,
    required this.amount,
    this.notes,
    this.dueDate,
    this.isPaid = false,
  });

  final String id;
  final String source;   // person or institution
  final double amount;
  final String? notes;
  final DateTime? dueDate;
  final bool isPaid;

  factory ExternalDebt.fromJson(Map<String, dynamic> json) => ExternalDebt(
        id: json['id'] as String,
        source: json['source'] as String,
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String?,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        isPaid: json['is_paid'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'amount': amount,
        'notes': notes,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'is_paid': isPaid,
      };

  @override
  List<Object?> get props => [id, source, amount];
}

// ══ INVESTMENT ════════════════════════════════════════════════════
class Investment extends Equatable {
  const Investment({
    required this.id,
    required this.type,
    required this.amount,
    required this.unit,
    this.notes,
    this.purchaseDate,
  });

  final String id;
  final String type;   // Gold, Silver, Stocks, etc.
  final double amount;
  final String unit;   // EGP, USD, g, oz, shares
  final String? notes;
  final DateTime? purchaseDate;

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        unit: json['unit'] as String,
        notes: json['notes'] as String?,
        purchaseDate: json['purchase_date'] != null
            ? DateTime.parse(json['purchase_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'unit': unit,
        'notes': notes,
        'purchase_date': purchaseDate?.toIso8601String().split('T').first,
      };

  @override
  List<Object?> get props => [id, type, amount, unit];
}

// ══ TRANSACTION ═══════════════════════════════════════════════════
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    required this.accountName,
    this.notes,
    this.isIncome = false,
  });

  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String category;
  final String accountName;
  final String? notes;
  final bool isIncome;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        accountName: json['account_name'] as String,
        notes: json['notes'] as String?,
        isIncome: json['is_income'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T').first,
        'description': description,
        'amount': amount,
        'category': category,
        'account_name': accountName,
        'notes': notes,
        'is_income': isIncome,
      };

  @override
  List<Object?> get props => [id, date, description, amount];
}

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
  final Map<String, bool> history; // 'YYYY-MM-DD' → done
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
