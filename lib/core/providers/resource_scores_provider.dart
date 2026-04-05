import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engines/money/providers/money_providers.dart';
import '../../engines/time/providers/time_providers.dart';
import '../../engines/energy/providers/energy_providers.dart';
import '../../engines/health/providers/health_providers.dart';
import 'package:intl/intl.dart';

/// Resource scores (0-100) for the Command Center dashboard.
class ResourceScores {
  const ResourceScores({
    this.money = 0,
    this.time = 0,
    this.energy = 0,
    this.health = 0,
  });
  final int money;
  final int time;
  final int energy;
  final int health;

  int get overall => ((money + time + energy + health) / 4).round();
}

final resourceScoresProvider = Provider<ResourceScores>((ref) {
  // Money score: based on debt ratio and savings
  final summary = ref.watch(financeSummaryProvider);
  int moneyScore = 50;
  if (summary.totalDebt > 0) {
    final debtRatio = summary.totalSavings / (summary.totalDebt + 1);
    moneyScore = (debtRatio * 50).clamp(0, 50).round();
  }
  if (summary.totalSavings > 0) moneyScore += 20;
  if (summary.remainingLimit > 0) moneyScore += 15;
  if (summary.todaySpend == 0) moneyScore += 15;
  moneyScore = moneyScore.clamp(0, 100);

  // Time score: based on schedule adherence (simplified)
  final blocks = ref.watch(scheduleProvider('normal')).value ?? [];
  int timeScore = blocks.isEmpty ? 30 : 60; // Has a schedule = baseline 60

  // Energy score: based on focus sessions today
  final sessions = ref.watch(focusSessionsProvider).value ?? [];
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final todayFocus = sessions
      .where((s) => DateFormat('yyyy-MM-dd').format(s.date) == todayKey && s.completed)
      .fold(0, (sum, s) => sum + s.actualMinutes);
  int energyScore = (todayFocus / 120 * 100).clamp(0, 100).round(); // 2hrs = 100%

  // Health score: based on habits completion
  final habitsToday = ref.watch(habitsTodayProvider);
  int healthScore = (habitsToday.pct * 100).round();

  return ResourceScores(
    money: moneyScore,
    time: timeScore,
    energy: energyScore,
    health: healthScore,
  );
});
