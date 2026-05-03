import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// SCHEDULE MODE MODEL
// ══════════════════════════════════════════════════════════════

class ScheduleMode {
  const ScheduleMode({
    required this.id,
    required this.label,
    required this.emoji,
    required this.colorHex,
  });

  final String id;      // unique key, used in ScheduleBlock.scheduleMode
  final String label;   // display name
  final String emoji;
  final int colorHex;   // ARGB int, e.g. 0xFF_FFD700

  Color get color => Color(colorHex);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'emoji': emoji,
        'colorHex': colorHex,
      };

  factory ScheduleMode.fromJson(Map<String, dynamic> j) => ScheduleMode(
        id: j['id'] as String,
        label: j['label'] as String,
        emoji: j['emoji'] as String,
        colorHex: j['colorHex'] as int,
      );

  ScheduleMode copyWith({
    String? id,
    String? label,
    String? emoji,
    int? colorHex,
  }) =>
      ScheduleMode(
        id: id ?? this.id,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
        colorHex: colorHex ?? this.colorHex,
      );
}

// ── Built-in default modes ────────────────────────────────────
final _defaultModes = [
  ScheduleMode(
      id: 'normal',
      label: 'Normal',
      emoji: '🏗️',
      colorHex: AppColors.gold.toARGB32()),
  ScheduleMode(
      id: 'fasting',
      label: 'Fasting',
      emoji: '🌙',
      colorHex: AppColors.fasting.toARGB32()),
  ScheduleMode(
      id: 'friday',
      label: 'Friday',
      emoji: '✨',
      colorHex: AppColors.deen.toARGB32()),
  ScheduleMode(
      id: 'cairo',
      label: 'Cairo',
      emoji: '🏙️',
      colorHex: AppColors.learn.toARGB32()),
];

// ══════════════════════════════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════════════════════════════

class ScheduleModesNotifier extends AsyncNotifier<List<ScheduleMode>> {
  @override
  Future<List<ScheduleMode>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefScheduleModes);
    if (raw == null) return List.of(_defaultModes);
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(ScheduleMode.fromJson)
          .toList();
      return list.isEmpty ? List.of(_defaultModes) : list;
    } catch (_) {
      return List.of(_defaultModes);
    }
  }

  Future<void> _persist(List<ScheduleMode> modes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefScheduleModes,
      jsonEncode(modes.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> add(ScheduleMode mode) async {
    final current = state.value ?? List.of(_defaultModes);
    final updated = [...current, mode];
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> updateMode(ScheduleMode mode) async {
    final current = state.value ?? List.of(_defaultModes);
    final updated = current.map((m) => m.id == mode.id ? mode : m).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final current = state.value ?? List.of(_defaultModes);
    if (current.length <= 1) return; // keep at least one mode
    final updated = current.where((m) => m.id != id).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = List.of(state.value ?? _defaultModes);
    if (newIndex > oldIndex) newIndex--;
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    state = AsyncData(current);
    await _persist(current);
  }
}

final scheduleModesProvider =
    AsyncNotifierProvider<ScheduleModesNotifier, List<ScheduleMode>>(
        ScheduleModesNotifier.new);
