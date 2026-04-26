import 'package:equatable/equatable.dart';

// ══════════════════════════════════════════════════════════════
// USER CATEGORY
// ══════════════════════════════════════════════════════════════

class UserCategory extends Equatable {
  const UserCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.engine,
    this.key,
    this.order = 0,
  });

  final String id;
  final String name;    // Display label — e.g. 'Deen', 'Food'
  final String emoji;
  final String engine;  // 'schedule' | 'transaction'
  final String? key;    // For schedule categories: short key stored in DB (e.g. 'deen')
  final int order;

  /// What gets stored in schedule_blocks.category_key or transactions.category
  String get storageKey => key ?? name;

  factory UserCategory.fromJson(Map<String, dynamic> json) => UserCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📌',
        engine: json['engine'] as String? ?? 'transaction',
        key: json['key'] as String?,
        order: json['order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'engine': engine,
        'key': key,
        'order': order,
      };

  UserCategory copyWith({
    String? name,
    String? emoji,
    int? order,
  }) =>
      UserCategory(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        engine: engine,
        key: key,
        order: order ?? this.order,
      );

  @override
  List<Object?> get props => [id, engine, storageKey];
}

// ── Default seeds ──────────────────────────────────────────────

const kDefaultScheduleCategories = [
  UserCategory(id: '', name: 'Deen',     emoji: '🕌', engine: 'schedule', key: 'deen',    order: 0),
  UserCategory(id: '', name: 'Learning', emoji: '📖', engine: 'schedule', key: 'learn',   order: 1),
  UserCategory(id: '', name: 'Project',  emoji: '🚀', engine: 'schedule', key: 'project', order: 2),
  UserCategory(id: '', name: 'Health',   emoji: '🚶', engine: 'schedule', key: 'health',  order: 3),
  UserCategory(id: '', name: 'Work',     emoji: '🏗️', engine: 'schedule', key: 'work',    order: 4),
  UserCategory(id: '', name: 'Rest',     emoji: '💤', engine: 'schedule', key: 'rest',    order: 5),
  UserCategory(id: '', name: 'Fasting',  emoji: '🌙', engine: 'schedule', key: 'fast',    order: 6),
  UserCategory(id: '', name: 'Commute',  emoji: '🚗', engine: 'schedule', key: 'com',     order: 7),
];

const kDefaultTxCategories = [
  UserCategory(id: '', name: 'General',   emoji: '💰', engine: 'transaction', order: 0),
  UserCategory(id: '', name: 'Food',      emoji: '🍽️', engine: 'transaction', order: 1),
  UserCategory(id: '', name: 'Transport', emoji: '🚗', engine: 'transaction', order: 2),
  UserCategory(id: '', name: 'Bills',     emoji: '📋', engine: 'transaction', order: 3),
  UserCategory(id: '', name: 'Shopping',  emoji: '🛍️', engine: 'transaction', order: 4),
  UserCategory(id: '', name: 'Health',    emoji: '💊', engine: 'transaction', order: 5),
  UserCategory(id: '', name: 'Personal',  emoji: '👤', engine: 'transaction', order: 6),
  UserCategory(id: '', name: 'Business',  emoji: '💼', engine: 'transaction', order: 7),
  UserCategory(id: '', name: 'Education', emoji: '🎓', engine: 'transaction', order: 8),
  UserCategory(id: '', name: 'Transfer',  emoji: '🔄', engine: 'transaction', order: 9),
];
