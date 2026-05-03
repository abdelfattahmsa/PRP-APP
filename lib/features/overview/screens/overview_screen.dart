import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/onboarding_checklist_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/checkin/screens/daily_checkin_screen.dart';
import '../../../shared/models/all_providers.dart';
import '../../../engines/money/data/models/money_models.dart' show FinanceSummary;
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';

// Ticks every second for the live clock
final _clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

// ── Breakpoint for 5-row desktop layout ─────────────────────────
// Use ≥800 px as the "PC" threshold (covers tablets in landscape too)
const _kDesktopBreak = 800.0;

// ══════════════════════════════════════════════════════════════
// OVERVIEW SCREEN
// ══════════════════════════════════════════════════════════════
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= _kDesktopBreak;

    return isDesktop
        ? const _DesktopOverview()
        : const _MobileOverview();
  }
}

// ══════════════════════════════════════════════════════════════
// DESKTOP  — 5 equal-height rows filling the screen
// ══════════════════════════════════════════════════════════════
class _DesktopOverview extends ConsumerWidget {
  const _DesktopOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final currentUser = ref.watch(currentUserProvider);
    final now = ref.watch(_clockProvider).value ?? DateTime.now();
    final summary = ref.watch(financeSummaryProvider);
    final habitsToday = ref.watch(habitsTodayProvider);
    final sessAsync = ref.watch(focusSessionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final scores = ref.watch(resourceScoresProvider);
    final currency = ref.watch(baseCurrencyProvider).asData?.value ?? 'EGP';
    final moodAsync = ref.watch(moodProvider);
    final checklistItems = ref.watch(checklistProvider);
    final checklistDismissed =
        ref.watch(checklistDismissedProvider).asData?.value ?? false;

    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayFocusMin = sessAsync.value
            ?.where((s) =>
                s.completed && DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
            .fold(0, (s, sess) => s + sess.actualMinutes) ??
        0;
    final activeGoals =
        goalsAsync.value?.where((g) => g.status == 'active').length ?? 0;
    final netWorth =
        summary.totalSavings + summary.totalCurrent - summary.totalDebt;
    final fmt = NumberFormat('#,##0', 'en_US');
    final allDone = checklistItems.every((i) => i.isDone);

    // Today's morning/evening mood
    final todayDStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    MoodEntry? morningMood = moodAsync.value?.where((e) {
      final d = e.timestamp;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
              todayDStr &&
          e.period == 'morning';
    }).firstOrNull;
    MoodEntry? eveningMood = moodAsync.value?.where((e) {
      final d = e.timestamp;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
              todayDStr &&
          e.period == 'evening';
    }).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final rowH = constraints.maxHeight / 5;
          return Column(
            children: [
              // ── ROW 1: Greeting + date/time + checklist ──────────
              SizedBox(
                height: rowH,
                child: _Row1Greeting(
                  user: currentUser,
                  now: now,
                  textSec: textSec,
                  checklistItems: checklistItems,
                  checklistDismissed: checklistDismissed,
                  allDone: allDone,
                  isDark: isDark,
                ),
              ),

              // ── ROW 2: Pillar scores ──────────────────────────────
              SizedBox(
                height: rowH,
                child: _Row2Scores(scores: scores, isDark: isDark),
              ),

              // ── ROW 3: Four pillar summary cards ─────────────────
              SizedBox(
                height: rowH,
                child: _Row3PillarSummaries(
                  summary: summary,
                  currency: currency,
                  fmt: fmt,
                  netWorth: netWorth,
                  todayFocusMin: todayFocusMin,
                  activeGoals: activeGoals,
                  habitsToday: habitsToday,
                  morningMood: morningMood,
                  eveningMood: eveningMood,
                  isDark: isDark,
                ),
              ),

              // ── ROW 4: Analytics / Daily Check-in banner ─────────
              SizedBox(
                height: rowH,
                child: _Row4Analytics(
                  sessions: sessAsync.value ?? [],
                  isDark: isDark,
                ),
              ),

              // ── ROW 5: Habits + Goals ─────────────────────────────
              SizedBox(
                height: rowH,
                child: _Row5HabitsGoals(isDark: isDark, textSec: textSec),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MOBILE  — original scrollable layout (preserved)
// ══════════════════════════════════════════════════════════════
class _MobileOverview extends ConsumerWidget {
  const _MobileOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final currentUser = ref.watch(currentUserProvider);
    final now = ref.watch(_clockProvider).value ?? DateTime.now();
    final summary = ref.watch(financeSummaryProvider);
    final habitsToday = ref.watch(habitsTodayProvider);
    final sessAsync = ref.watch(focusSessionsProvider);
    final scores = ref.watch(resourceScoresProvider);
    final currency = ref.watch(baseCurrencyProvider).asData?.value ?? 'EGP';
    final moodAsync = ref.watch(moodProvider);
    final checklistItems = ref.watch(checklistProvider);
    final checklistDismissed =
        ref.watch(checklistDismissedProvider).asData?.value ?? false;

    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayFocusMin = sessAsync.value
            ?.where((s) =>
                s.completed && DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
            .fold(0, (s, sess) => s + sess.actualMinutes) ??
        0;
    final netWorth =
        summary.totalSavings + summary.totalCurrent - summary.totalDebt;
    final fmt = NumberFormat('#,##0', 'en_US');
    final allDone = checklistItems.every((i) => i.isDone);

    final todayDStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    MoodEntry? morningMood = moodAsync.value?.where((e) {
      final d = e.timestamp;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
              todayDStr &&
          e.period == 'morning';
    }).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // Greeting
            _GreetingHeader(user: currentUser, now: now, textSecondary: textSec),
            const Gap(16),

            // Getting Started Checklist
            if (!checklistDismissed && !allDone) ...[
              _OnboardingChecklistCard(items: checklistItems),
              const Gap(16),
            ],

            // Daily Check-in Banner
            const CheckinBanner(),
            const Gap(16),

            // KPI Grid
            BentoGrid(
              children: [
                BentoCell(
                  child: KpiCard(
                    label: 'Net Worth',
                    value: '$currency ${fmt.format(netWorth)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.success,
                    subtitle: 'Today −${fmt.format(summary.todaySpend)}',
                    onTap: () => context.go(Routes.financeOverview),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Habits Today',
                    value: '${habitsToday.done} / ${habitsToday.total}',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.accent,
                    subtitle: '${(habitsToday.pct * 100).toStringAsFixed(0)}% done',
                    trend: habitsToday.done == habitsToday.total && habitsToday.total > 0
                        ? 'All done!'
                        : null,
                    trendUp: true,
                    onTap: () => context.go(Routes.healthHabits),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Focus Today',
                    value: '${todayFocusMin}m',
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.warning,
                    subtitle: sessAsync.isLoading ? 'Loading...' : null,
                    onTap: () => context.go(Routes.energyFocus),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Mood',
                    value: morningMood?.emoji ?? '—',
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    iconColor: AppColors.gold,
                    subtitle: morningMood != null ? 'Morning: ${morningMood.label}' : 'Not logged yet',
                    onTap: () => context.go(Routes.energyMood),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Resource Scores
            _ResourceScoreCard(scores: scores),
            const Gap(24),

            // Today's Habits
            BentoSectionHeader(
              "Today's Habits",
              action: TextButton(
                onPressed: () => context.go(Routes.healthHabits),
                child: const Text('All habits', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            const _HabitsList(),
            const Gap(24),

            // Active Goals
            BentoSectionHeader(
              'Active Goals',
              action: TextButton(
                onPressed: () => context.go(Routes.energyGoals),
                child: const Text('All goals', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            const _GoalsList(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ROW 1 — Greeting + date/time + Getting Started
// ══════════════════════════════════════════════════════════════
class _Row1Greeting extends ConsumerWidget {
  const _Row1Greeting({
    required this.user,
    required this.now,
    required this.textSec,
    required this.checklistItems,
    required this.checklistDismissed,
    required this.allDone,
    required this.isDark,
  });

  final dynamic user;
  final DateTime now;
  final Color textSec;
  final List<ChecklistItem> checklistItems;
  final bool checklistDismissed;
  final bool allDone;
  final bool isDark;

  String get _greeting {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = (user?.fullName as String?)?.split(' ').first ?? 'there';
    final greeting = _greeting;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Greeting + date
          Expanded(
            flex: 3,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$greeting, $firstName 👋',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Gap(4),
                  Text(
                    DateFormat('EEEE, d MMMM y').format(now),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textSec),
                  ),
                  const Gap(8),
                  const CheckinBanner(),
                ],
              ),
            ),
          ),
          const Gap(10),
          // Middle: Live clock
          AppCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(now),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 2,
                      ),
                ),
                const Gap(4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    now.timeZoneName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontFamily: 'Roboto',
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          // Right: Getting Started checklist (if active) or quick status
          Expanded(
            flex: 2,
            child: !checklistDismissed && !allDone
                ? _CompactChecklist(items: checklistItems, isDark: isDark)
                : AppCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 28),
                        const Gap(6),
                        Text(
                          'All set up!',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactChecklist extends ConsumerWidget {
  const _CompactChecklist({required this.items, required this.isDark});
  final List<ChecklistItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = items.where((i) => i.isDone).length;
    final total = items.length;
    final accent = Theme.of(context).colorScheme.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.checklist_rounded, color: accent, size: 14),
            const Gap(6),
            Text(
              'Getting Started',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$done/$total',
              style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto'),
            ),
            const Gap(4),
            GestureDetector(
              onTap: () =>
                  ref.read(checklistDismissedProvider.notifier).dismiss(),
              child: Icon(Icons.close_rounded,
                  size: 13,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary),
            ),
          ]),
          const Gap(6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              minHeight: 3,
              backgroundColor:
                  isDark ? AppColors.border : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const Gap(8),
          ...items.where((i) => !i.isDone).take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: GestureDetector(
                  onTap: () => context.go(item.route),
                  child: Row(children: [
                    Icon(item.icon,
                        size: 12,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary),
                    const Gap(6),
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ROW 2 — Pillar scores as gauges
// ══════════════════════════════════════════════════════════════
class _Row2Scores extends StatelessWidget {
  const _Row2Scores({required this.scores, required this.isDark});
  final ResourceScores scores;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PillarScoreCard(
            label: 'Money',
            emoji: '💰',
            score: scores.money,
            color: AppColors.success,
            route: Routes.financeOverview,
            description: 'Finance health',
          ),
          const Gap(10),
          _PillarScoreCard(
            label: 'Time',
            emoji: '⏰',
            score: scores.time,
            color: AppColors.gold,
            route: Routes.timeOverview,
            description: 'Schedule & tasks',
          ),
          const Gap(10),
          _PillarScoreCard(
            label: 'Energy',
            emoji: '⚡',
            score: scores.energy,
            color: AppColors.warning,
            route: Routes.energyOverview,
            description: 'Focus & mood',
          ),
          const Gap(10),
          _PillarScoreCard(
            label: 'Health',
            emoji: '❤️',
            score: scores.health,
            color: AppColors.health,
            route: Routes.healthOverview,
            description: 'Body & habits',
          ),
          const Gap(10),
          // Overall score card
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(Routes.overview),
              child: AppCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${scores.overall}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(scores.overall),
                      ),
                    ),
                    Text('/100',
                        style: TextStyle(
                            fontSize: 11,
                            color: _scoreColor(scores.overall)
                                .withValues(alpha: 0.6),
                            fontFamily: 'Roboto')),
                    const Gap(4),
                    Text(
                      'Overall',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 75) return AppColors.success;
    if (s >= 45) return AppColors.warning;
    return AppColors.error;
  }
}

class _PillarScoreCard extends StatelessWidget {
  const _PillarScoreCard({
    required this.label,
    required this.emoji,
    required this.score,
    required this.color,
    required this.route,
    required this.description,
  });

  final String label;
  final String emoji;
  final int score;
  final Color color;
  final String route;
  final String description;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: () => context.go(route),
          child: AppCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 5,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                  ]),
                ),
                const Gap(6),
                Text(
                  '$score',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// ROW 3 — Four pillar summaries
// ══════════════════════════════════════════════════════════════
class _Row3PillarSummaries extends StatelessWidget {
  const _Row3PillarSummaries({
    required this.summary,
    required this.currency,
    required this.fmt,
    required this.netWorth,
    required this.todayFocusMin,
    required this.activeGoals,
    required this.habitsToday,
    required this.morningMood,
    required this.eveningMood,
    required this.isDark,
  });

  final FinanceSummary summary;
  final String currency;
  final NumberFormat fmt;
  final double netWorth;
  final int todayFocusMin;
  final int activeGoals;
  final ({int done, int total, double pct}) habitsToday;
  final MoodEntry? morningMood;
  final MoodEntry? eveningMood;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Finance card
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(Routes.financeOverview),
              child: AppCard(
                child: _PillarSummaryContent(
                  icon: '💰',
                  title: 'Finance',
                  color: AppColors.success,
                  rows: [
                    _SumRow('Net Worth',
                        '$currency ${fmt.format(netWorth)}',
                        netWorth >= 0 ? AppColors.success : AppColors.error),
                    _SumRow('Today Spent',
                        '−${fmt.format(summary.todaySpend)}',
                        AppColors.error),
                    _SumRow('CC Balance',
                        fmt.format(summary.totalCCFromCards),
                        AppColors.warning),
                    _SumRow('Monthly Obl.',
                        fmt.format(summary.totalMonthlyObligation),
                        AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const Gap(10),
          // Time card
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(Routes.timeOverview),
              child: AppCard(
                child: _PillarSummaryContent(
                  icon: '⏰',
                  title: 'Time',
                  color: AppColors.gold,
                  rows: [
                    _SumRow('Schedule', 'Go to schedule →',
                        AppColors.gold),
                  ],
                  extraWidget: _ScheduleMiniWidget(isDark: isDark),
                ),
              ),
            ),
          ),
          const Gap(10),
          // Energy card
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(Routes.energyOverview),
              child: AppCard(
                child: _PillarSummaryContent(
                  icon: '⚡',
                  title: 'Energy',
                  color: AppColors.warning,
                  rows: [
                    _SumRow(
                        'Focus Today', '${todayFocusMin}m', AppColors.warning),
                    _SumRow('Active Goals', '$activeGoals', AppColors.gold),
                    _SumRow(
                      'Morning Mood',
                      morningMood != null
                          ? '${morningMood!.emoji} ${morningMood!.label}'
                          : '— Not logged',
                      morningMood != null
                          ? Color(morningMood!.colorValue)
                          : AppColors.textSecondary,
                    ),
                    _SumRow(
                      'Evening Mood',
                      eveningMood != null
                          ? '${eveningMood!.emoji} ${eveningMood!.label}'
                          : '— Not logged',
                      eveningMood != null
                          ? Color(eveningMood!.colorValue)
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(10),
          // Health card
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(Routes.healthOverview),
              child: AppCard(
                child: _PillarSummaryContent(
                  icon: '❤️',
                  title: 'Health',
                  color: AppColors.health,
                  rows: [
                    _SumRow(
                        'Habits Today',
                        '${habitsToday.done} / ${habitsToday.total}',
                        AppColors.accent),
                    _SumRow(
                        'Progress',
                        '${(habitsToday.pct * 100).toStringAsFixed(0)}%',
                        habitsToday.pct >= 0.8
                            ? AppColors.success
                            : habitsToday.pct >= 0.5
                                ? AppColors.warning
                                : AppColors.error),
                  ],
                  extraWidget: _HabitsMiniProgress(
                    done: habitsToday.done,
                    total: habitsToday.total,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SumRow {
  const _SumRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _PillarSummaryContent extends StatelessWidget {
  const _PillarSummaryContent({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
    this.extraWidget,
  });

  final String icon;
  final String title;
  final Color color;
  final List<_SumRow> rows;
  final Widget? extraWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const Gap(6),
          Text(
            title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ]),
        const Gap(8),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontFamily: 'Roboto')),
                  Text(r.value,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: r.color,
                          fontFamily: 'Roboto')),
                ],
              ),
            )),
        if (extraWidget != null) ...[
          const Gap(6),
          extraWidget!,
        ],
      ],
    );
  }
}

class _ScheduleMiniWidget extends StatelessWidget {
  const _ScheduleMiniWidget({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go(Routes.timeSchedule),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.view_timeline_outlined,
                size: 12, color: AppColors.gold),
            const Gap(6),
            Text('View schedule',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.gold,
                    fontFamily: 'Roboto')),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 9, color: AppColors.gold),
          ]),
        ),
      );
}

class _HabitsMiniProgress extends StatelessWidget {
  const _HabitsMiniProgress(
      {required this.done, required this.total, required this.isDark});
  final int done;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 6,
          backgroundColor: isDark ? AppColors.border : AppColors.lightBorder,
          valueColor: AlwaysStoppedAnimation(
              pct >= 1.0 ? AppColors.success : AppColors.accent),
        ),
      ),
      const Gap(3),
      Text(
        pct >= 1.0 ? '🎉 All habits done!' : '$done of $total done',
        style: TextStyle(
            fontSize: 9,
            color: pct >= 1.0
                ? AppColors.success
                : AppColors.textSecondary,
            fontFamily: 'Roboto'),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// ROW 4 — Analytics (7-day focus chart)
// ══════════════════════════════════════════════════════════════
class _Row4Analytics extends StatefulWidget {
  const _Row4Analytics({required this.sessions, required this.isDark});
  final List<FocusSession> sessions;
  final bool isDark;

  @override
  State<_Row4Analytics> createState() => _Row4AnalyticsState();
}

class _Row4AnalyticsState extends State<_Row4Analytics> {
  String _range = 'week'; // 'day' | 'week' | 'month'

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sessions = widget.sessions;

    // Build chart data based on range
    late List<({DateTime d, int mins})> chartData;
    late String chartLabel;

    if (_range == 'day') {
      // Last 24h in 4h buckets
      final now = DateTime.now();
      chartData = List.generate(6, (i) {
        final hour = now.subtract(Duration(hours: (5 - i) * 4));
        final mins = sessions
            .where((s) =>
                s.completed &&
                s.date.difference(hour).inHours.abs() < 4)
            .fold(0, (s, e) => s + e.actualMinutes);
        return (d: hour, mins: mins);
      });
      chartLabel = 'TODAY · 4H BUCKETS';
    } else if (_range == 'week') {
      chartData = List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final key = DateFormat('yyyy-MM-dd').format(d);
        final mins = sessions
            .where((s) =>
                s.completed &&
                DateFormat('yyyy-MM-dd').format(s.date) == key)
            .fold(0, (s, e) => s + e.actualMinutes);
        return (d: d, mins: mins);
      });
      chartLabel = 'LAST 7 DAYS · FOCUS MINUTES';
    } else {
      // month — last 4 weeks
      chartData = List.generate(4, (i) {
        final weekStart =
            DateTime.now().subtract(Duration(days: (3 - i) * 7 + 6));
        final weekEnd =
            DateTime.now().subtract(Duration(days: (3 - i) * 7));
        final mins = sessions
            .where((s) =>
                s.completed &&
                !s.date.isBefore(weekStart) &&
                !s.date.isAfter(weekEnd))
            .fold(0, (s, e) => s + e.actualMinutes);
        return (d: weekStart, mins: mins);
      });
      chartLabel = 'LAST 4 WEEKS · FOCUS MINUTES';
    }

    final maxMins = chartData.fold(1, (m, d) => d.mins > m ? d.mins : m);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + toggle
            Row(children: [
              const Icon(Icons.insights_rounded,
                  size: 14, color: AppColors.gold),
              const Gap(8),
              Text(chartLabel,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 9,
                      color: AppColors.gold,
                      letterSpacing: 1.5)),
              const Spacer(),
              // Range pills
              _RangePill(
                  label: 'Day',
                  selected: _range == 'day',
                  onTap: () => setState(() => _range = 'day')),
              const Gap(4),
              _RangePill(
                  label: 'Week',
                  selected: _range == 'week',
                  onTap: () => setState(() => _range = 'week')),
              const Gap(4),
              _RangePill(
                  label: 'Month',
                  selected: _range == 'month',
                  onTap: () => setState(() => _range = 'month')),
            ]),
            const Gap(10),
            // Bar chart
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartData.map((d) {
                  String lbl;
                  if (_range == 'day') {
                    lbl = DateFormat('Ha').format(d.d);
                  } else if (_range == 'week') {
                    lbl = DateFormat('EEE').format(d.d).substring(0, 2);
                  } else {
                    lbl = 'W${chartData.indexOf(d) + 1}';
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (d.mins > 0)
                            Text('${d.mins}m',
                                style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 8,
                                    color: AppColors.textSecondary)),
                          const Gap(2),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: 500.ms,
                                curve: Curves.easeOut,
                                height: maxMins > 0 ? 60 * (d.mins / maxMins) : 0,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const Gap(4),
                          Text(lbl,
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 8,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color:
                    selected ? AppColors.gold : AppColors.textSecondary),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// ROW 5 — Habits of the day + Active Goals
// ══════════════════════════════════════════════════════════════
class _Row5HabitsGoals extends StatelessWidget {
  const _Row5HabitsGoals({
    required this.isDark,
    required this.textSec,
  });

  final bool isDark;
  final Color textSec;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Habits
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.accent),
                    const Gap(6),
                    Text("Today's Habits",
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(Routes.healthHabits),
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2)),
                      child: const Text('All',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ]),
                  const Gap(6),
                  const Expanded(child: _HabitsList()),
                ],
              ),
            ),
          ),
          const Gap(10),
          // Goals
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.flag_outlined,
                        size: 14, color: AppColors.accent),
                    const Gap(6),
                    const Text('Active Goals',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(Routes.energyGoals),
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2)),
                      child: const Text('All',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ]),
                  const Gap(6),
                  const Expanded(child: _GoalsList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED WIDGETS (used in both mobile + desktop)
// ══════════════════════════════════════════════════════════════

/// Self-contained habits list — watches habitsProvider directly.
class _HabitsList extends ConsumerWidget {
  const _HabitsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return habitsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) =>
          const Text('Error loading habits', style: TextStyle(fontSize: 11)),
      data: (habits) {
        if (habits.isEmpty) {
          return Center(
              child: Text('No habits yet',
                  style: TextStyle(color: textSec, fontSize: 11)));
        }
        final visible = habits.take(5).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          itemBuilder: (ctx, i) {
            final h = visible[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Text(h.icon, style: const TextStyle(fontSize: 16)),
                const Gap(8),
                Expanded(
                    child: Text(h.name,
                        style: TextStyle(
                            fontSize: 11,
                            decoration: h.isDoneToday
                                ? TextDecoration.lineThrough
                                : null,
                            color: h.isDoneToday ? textSec : null),
                        overflow: TextOverflow.ellipsis)),
                Icon(
                  h.isDoneToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: h.isDoneToday ? AppColors.success : textSec,
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

/// Self-contained goals list — watches goalsProvider directly.
class _GoalsList extends ConsumerWidget {
  const _GoalsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return goalsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) =>
          const Text('Error loading goals', style: TextStyle(fontSize: 11)),
      data: (goals) {
        final active =
            goals.where((g) => g.status == 'active').take(4).toList();
        if (active.isEmpty) {
          return Center(
              child: Text('No active goals',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11)));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: active.length,
          itemBuilder: (ctx, i) {
            final g = active[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(g.title,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis)),
                      Text('${g.progress}%',
                          style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700)),
                    ]),
                    const Gap(3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: g.progress / 100,
                        minHeight: 3,
                        backgroundColor: isDark
                            ? AppColors.border
                            : AppColors.lightBorder,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ]),
            );
          },
        );
      },
    );
  }
}

// ── Resource Score Card (used in mobile) ──────────────────────
class _ResourceScoreCard extends StatelessWidget {
  const _ResourceScoreCard({required this.scores});
  final ResourceScores scores;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Resource Score',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _scoreColor(scores.overall).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${scores.overall}',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(scores.overall))),
                Text(' / 100',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: _scoreColor(scores.overall)
                            .withValues(alpha: 0.6))),
              ]),
            ),
          ]),
          const Gap(16),
          Row(children: [
            _ScoreGauge(label: 'Money', icon: '💰', score: scores.money, color: AppColors.success),
            _ScoreGauge(label: 'Time', icon: '⏰', score: scores.time, color: AppColors.gold),
            _ScoreGauge(label: 'Energy', icon: '⚡', score: scores.energy, color: AppColors.warning),
            _ScoreGauge(label: 'Health', icon: '❤️', score: scores.health, color: AppColors.health),
          ]),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 75) return AppColors.success;
    if (s >= 45) return AppColors.warning;
    return AppColors.error;
  }
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.label, required this.icon, required this.score, required this.color});
  final String label; final String icon; final int score; final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final track = isDark ? AppColors.border : AppColors.lightBorder;
    return Expanded(child: Column(children: [
      SizedBox(width: 56, height: 56, child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(child: CircularProgressIndicator(value: score / 100, strokeWidth: 5, backgroundColor: track, valueColor: AlwaysStoppedAnimation(color), strokeCap: StrokeCap.round)),
        Text(icon, style: const TextStyle(fontSize: 18)),
      ])),
      const Gap(6),
      Text('$score', style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: textSec)),
    ]));
  }
}

// ── Greeting Header (mobile only) ──────────────────────────────
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.user, required this.now, required this.textSecondary});
  final dynamic user; final DateTime now; final Color textSecondary;

  String get _greeting {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (user?.fullName as String?)?.split(' ').first ?? 'there';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$_greeting, $firstName', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Gap(4),
        Text(DateFormat('EEEE, d MMM').format(now), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(DateFormat('HH:mm').format(now), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Roboto', fontWeight: FontWeight.w600, color: AppColors.accent)),
        const Gap(2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(now.timeZoneName, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent, fontFamily: 'Roboto')),
        ),
      ]),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// ONBOARDING CHECKLIST CARD  (mobile full-size version)
// ══════════════════════════════════════════════════════════════
class _OnboardingChecklistCard extends ConsumerWidget {
  const _OnboardingChecklistCard({required this.items});
  final List<ChecklistItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final accent = Theme.of(context).colorScheme.primary;
    final doneCount = items.where((i) => i.isDone).length;
    final total = items.length;
    final pct = total > 0 ? doneCount / total : 0.0;
    final undone = items.where((i) => !i.isDone).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.checklist_rounded, color: accent, size: 18),
          const Gap(8),
          Text('Getting Started', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('$doneCount / $total', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Roboto')),
          ),
          const Gap(8),
          GestureDetector(
            onTap: () => ref.read(checklistDismissedProvider.notifier).dismiss(),
            child: Icon(Icons.close_rounded, size: 16, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
          ),
        ]),
        const Gap(10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: borderColor, valueColor: AlwaysStoppedAnimation(accent)),
        ),
        const Gap(12),
        ...undone.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => context.go(item.route),
                child: Row(children: [
                  Icon(item.icon, size: 16, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  const Gap(10),
                  Expanded(child: Text(item.title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                ]),
              ),
            )),
        if (items.length - doneCount > 3)
          Text('+${items.length - doneCount - undone.length} more', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
      ]),
    );
  }
}
