import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:equatable/equatable.dart';
import 'package:health/health.dart';

// ══ Result model ══════════════════════════════════════════════════
class HealthSyncResult extends Equatable {
  const HealthSyncResult({
    required this.available,
    required this.permissionGranted,
    this.steps = 0,
    this.activeCaloriesBurned = 0,
    this.avgHeartRate,
    this.latestWeightKg,
    this.sleepHours = 0.0,
    this.syncedAt,
    this.errorMessage,
  });

  const HealthSyncResult.unavailable()
      : available = false,
        permissionGranted = false,
        steps = 0,
        activeCaloriesBurned = 0,
        avgHeartRate = null,
        latestWeightKg = null,
        sleepHours = 0.0,
        syncedAt = null,
        errorMessage = null;

  const HealthSyncResult.permissionDenied()
      : available = true,
        permissionGranted = false,
        steps = 0,
        activeCaloriesBurned = 0,
        avgHeartRate = null,
        latestWeightKg = null,
        sleepHours = 0.0,
        syncedAt = null,
        errorMessage = null;

  HealthSyncResult.withError(String msg)
      : available = true,
        permissionGranted = true,
        steps = 0,
        activeCaloriesBurned = 0,
        avgHeartRate = null,
        latestWeightKg = null,
        sleepHours = 0.0,
        syncedAt = null,
        errorMessage = msg;

  final bool available;
  final bool permissionGranted;
  final int steps;
  final int activeCaloriesBurned;
  final double? avgHeartRate;
  final double? latestWeightKg;
  final double sleepHours;
  final DateTime? syncedAt;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        available, permissionGranted, steps, activeCaloriesBurned,
        avgHeartRate, latestWeightKg, sleepHours, syncedAt, errorMessage,
      ];
}

class HealthDaySummary {
  const HealthDaySummary({
    required this.date,
    required this.steps,
    required this.activeCalories,
    this.avgHeartRate,
    this.sleepHours = 0.0,
  });
  final DateTime date;
  final int steps;
  final int activeCalories;
  final double? avgHeartRate;
  final double sleepHours;
}

// ══ Service ═══════════════════════════════════════════════════════
class HealthSyncService {
  HealthSyncService._();
  static final instance = HealthSyncService._();

  final _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  String get platformName {
    if (!isSupported) return 'Manual';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'Apple Health';
      case TargetPlatform.android:
        return 'Google Health Connect';
      default:
        return 'Manual';
    }
  }

  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    try {
      await _health.configure();
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  Future<HealthSyncResult> syncToday() async {
    if (!isSupported) return const HealthSyncResult.unavailable();
    try {
      await _health.configure();
      final hasPerms = await _health.hasPermissions(_types);
      if (hasPerms != true) {
        final granted = await _health.requestAuthorization(_types);
        if (!granted) return const HealthSyncResult.permissionDenied();
      }
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final data = await _health.getHealthDataFromTypes(
        startTime: dayStart,
        endTime: now,
        types: _types,
      );
      return _aggregate(_health.removeDuplicates(data), now);
    } catch (e) {
      return HealthSyncResult.withError('$e');
    }
  }

  Future<List<HealthDaySummary>> syncLastDays(int days) async {
    if (!isSupported) return [];
    try {
      await _health.configure();
      final hasPerms = await _health.hasPermissions(_types);
      if (hasPerms != true) {
        final granted = await _health.requestAuthorization(_types);
        if (!granted) return [];
      }
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _types,
      );
      final deduped = _health.removeDuplicates(data);

      final byDay = <String, List<HealthDataPoint>>{};
      for (final p in deduped) {
        final d = p.dateFrom;
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        (byDay[key] ??= []).add(p);
      }

      final summaries = byDay.entries.map((e) {
        final date = DateTime.parse(e.key);
        final r = _aggregate(e.value, date);
        return HealthDaySummary(
          date: date,
          steps: r.steps,
          activeCalories: r.activeCaloriesBurned,
          avgHeartRate: r.avgHeartRate,
          sleepHours: r.sleepHours,
        );
      }).toList();
      summaries.sort((a, b) => b.date.compareTo(a.date));
      return summaries;
    } catch (_) {
      return [];
    }
  }

  static HealthSyncResult _aggregate(List<HealthDataPoint> data, DateTime at) {
    int steps = 0;
    double calories = 0;
    final heartRates = <double>[];
    double sleepMins = 0;
    double? latestWeight;

    for (final p in data) {
      final v = p.value;
      if (v is! NumericHealthValue) continue;
      final n = v.numericValue.toDouble();
      switch (p.type) {
        case HealthDataType.STEPS:
          steps += n.toInt();
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += n;
        case HealthDataType.HEART_RATE:
          heartRates.add(n);
        case HealthDataType.WEIGHT:
          latestWeight ??= n;
        case HealthDataType.SLEEP_ASLEEP:
        case HealthDataType.SLEEP_DEEP:
        case HealthDataType.SLEEP_REM:
          sleepMins += p.dateTo.difference(p.dateFrom).inMinutes;
        default:
          break;
      }
    }

    return HealthSyncResult(
      available: true,
      permissionGranted: true,
      steps: steps,
      activeCaloriesBurned: calories.toInt(),
      avgHeartRate: heartRates.isEmpty
          ? null
          : heartRates.reduce((a, b) => a + b) / heartRates.length,
      latestWeightKg: latestWeight,
      sleepHours: sleepMins / 60.0,
      syncedAt: at,
    );
  }
}
