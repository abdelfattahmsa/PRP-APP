import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';

// ══════════════════════════════════════════════════════════════
// OVERVIEW — Dashboard "today at a glance"
// Dense, information-rich, zero wasted space
// ══════════════════════════════════════════════════════════════

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});
  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  late final _clock = Stream.periodic(const Duration(seconds: 30));

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);
    final habits = ref.watch(habitsTodayProvider);
    final summary = ref.watch(financeSummaryProvider);
    final goals = ref.watch(goalsProvider).value ?? [];
    final sessions = ref.watch(focusSessionsProvider).value ?? [];
    final calEvents = ref.watch(calendarProvider).value ?? [];
    final scores = ref.watch(resourceScoresProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final todayMins = sessions
        .where((s) => DateFormat('yyyy-MM-dd').format(s.date) == todayKey && s.completed)
        .fold(0, (sum, s) => sum + s.actualMinutes);

    // Schedule
    final schedAsync = ref.watch(scheduleProvider('normal'));
    final blocks = schedAsync.value ?? [];
    final nowMins = now.hour * 60 + now.minute;
    ScheduleBlock? curBlock;
    ScheduleBlock? nextBlock;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final nxt = i + 1 < blocks.length ? blocks[i + 1].minutesSinceMidnight : 24 * 60;
      if (nowMins >= b.minutesSinceMidnight && nowMins < nxt) {
        curBlock = b;
        if (i + 1 < blocks.length) nextBlock = blocks[i + 1];
        break;
      }
    }

    final upcoming = calEvents
        .where((e) => !e.isDone && DateTime(e.date.year, e.date.month, e.date.day).compareTo(today) >= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final activeGoals = goals.where((g) => g.status == 'active').toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    final isWide = Breakpoints.isWide(context);
    final pad = isWide ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(pad, isWide ? 28 : 48, pad, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF100B1C), AppColors.bg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.goldDim),
                            ),
                            const Gap(2),
                            Text(
                              DateFormat('EEEE, d MMMM').format(now),
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder(
                        stream: _clock,
                        builder: (_, __) => Text(
                          DateFormat('HH:mm').format(DateTime.now()),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── CONTENT ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Current block
                if (curBlock != null) ...[
                  _CurrentBlockCard(block: curBlock, nextBlock: nextBlock)
                      .animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),
                  const Gap(Spacing.md),
                ],

                // ── RESOURCE PULSE ──
                _ResourcePulse(scores: scores)
                    .animate(delay: 60.ms).fadeIn(duration: 300.ms),
                const Gap(Spacing.md),

                // ── STATS GRID ──
                _StatsGrid(
                  habits: habits,
                  todayMins: todayMins,
                  activeGoals: activeGoals.length,
                  summary: summary,
                  onTap: (route) => context.go(route),
                ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
                const Gap(Spacing.lg),

                // ── TWO-COLUMN on desktop ──
                if (isWide) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Events
                      Expanded(
                        child: _EventsSection(
                          upcoming: upcoming,
                          today: today,
                          onSeeAll: () => context.go(Routes.calendar),
                        ),
                      ),
                      const Gap(Spacing.md),
                      // Right: Goals
                      Expanded(
                        child: _GoalsSection(
                          goals: activeGoals,
                          onSeeAll: () => context.go(Routes.goals),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mobile: stack vertically
                  _EventsSection(
                    upcoming: upcoming,
                    today: today,
                    onSeeAll: () => context.go(Routes.calendar),
                  ),
                  const Gap(Spacing.lg),
                  _GoalsSection(
                    goals: activeGoals,
                    onSeeAll: () => context.go(Routes.goals),
                  ),
                ],
                const Gap(Spacing.lg),

                // Milestones
                _MilestonesStrip(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

String _fmt(double v) => NumberFormat('#,##0', 'en').format(v);

// ── CURRENT BLOCK ────────────────────────────────────────────

class _CurrentBlockCard extends StatelessWidget {
  const _CurrentBlockCard({required this.block, this.nextBlock});
  final ScheduleBlock block;
  final ScheduleBlock? nextBlock;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(block.categoryKey);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.10), AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Color bar
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
          const Gap(Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NOW',
                        style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: color, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                    const Gap(Spacing.sm),
                    Text(
                      block.time,
                      style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: color.withValues(alpha: 0.7)),
                    ),
                    if (block.duration != null) ...[
                      Text(
                        ' · ${block.duration}',
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                Text(
                  block.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (block.note != null && block.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      block.note!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (nextBlock != null)
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('NEXT', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 7, color: AppColors.textMuted, letterSpacing: 1)),
                  const Gap(2),
                  Text(nextBlock!.time, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── STATS GRID ───────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.habits,
    required this.todayMins,
    required this.activeGoals,
    required this.summary,
    required this.onTap,
  });
  final ({int done, int total, double pct}) habits;
  final int todayMins;
  final int activeGoals;
  final dynamic summary;
  final void Function(String route) onTap;

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.isWide(context);
    final cols = isWide ? 6 : 3;

    final stats = [
      _Stat('Habits', '${habits.done}/${habits.total}', habits.pct == 1.0 ? AppColors.success : AppColors.gold, Icons.check_circle_outline, Routes.habits),
      _Stat('Focus', '${todayMins}m', AppColors.pmp, Icons.timer_outlined, Routes.focus),
      _Stat('Goals', '$activeGoals', AppColors.kyberia, Icons.flag_outlined, Routes.goals),
      _Stat('CC Debt', 'EGP ${_fmt(summary.totalCC)}', AppColors.error, Icons.credit_card, Routes.finance),
      _Stat('Savings', 'EGP ${_fmt(summary.totalSavings)}', AppColors.gold, Icons.savings_outlined, Routes.finance),
      _Stat('Limit', 'EGP ${_fmt(summary.remainingLimit)}', summary.remainingLimit < 0 ? AppColors.error : AppColors.success, Icons.account_balance_outlined, Routes.finance),
    ];

    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacing.sm,
      crossAxisSpacing: Spacing.sm,
      childAspectRatio: isWide ? 2.2 : 1.6,
      children: stats.map((s) => _StatCard(stat: s, onTap: () => onTap(s.route))).toList(),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color, this.icon, this.route);
  final String label, value, route;
  final Color color;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.onTap});
  final _Stat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.cardHover,
        child: Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(stat.icon, size: 12, color: AppColors.textMuted),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      stat.label,
                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap(4),
              Text(
                stat.value,
                style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: stat.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── EVENTS SECTION ───────────────────────────────────────────

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.upcoming, required this.today, required this.onSeeAll});
  final List<CalendarEvent> upcoming;
  final DateTime today;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Upcoming Events', onAction: onSeeAll),
        if (upcoming.isEmpty)
          _EmptyHint(text: 'No upcoming events', icon: Icons.event_outlined)
        else
          for (final ev in upcoming.take(5)) ...[
            _EventTile(event: ev, today: today),
            const Gap(Spacing.xs),
          ],
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.today});
  final CalendarEvent event;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(event.typeKey);
    final daysAway = DateTime(event.date.year, event.date.month, event.date.day).difference(today).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const Gap(Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(DateFormat('d MMM').format(event.date), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(
              daysAway == 0 ? 'Today' : daysAway == 1 ? 'Tmrw' : '${daysAway}d',
              style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── GOALS SECTION ────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals, required this.onSeeAll});
  final List<Goal> goals;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Active Goals', onAction: onSeeAll),
        if (goals.isEmpty)
          _EmptyHint(text: 'No active goals', icon: Icons.flag_outlined)
        else
          for (final g in goals.take(4)) ...[
            _GoalTile(goal: g),
            const Gap(Spacing.xs),
          ],
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final pColor = goal.priority == 'high' ? AppColors.error : goal.priority == 'medium' ? AppColors.gold : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('${goal.progress}%', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: pColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(Spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: goal.progress / 100,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(pColor),
            ),
          ),
          const Gap(Spacing.xs),
          Row(
            children: [
              Text(DateFormat('d MMM').format(goal.targetDate), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                goal.daysRemaining < 0 ? 'Overdue' : '${goal.daysRemaining}d',
                style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: goal.daysRemaining < 0 ? AppColors.error : AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── MILESTONES ───────────────────────────────────────────────

class _MilestonesStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final milestones = [
      ('Product #1', 'Apr 10', AppColors.error),
      ('1st Client', 'May 1', AppColors.kyberia),
      ('Engaged', 'May 30', AppColors.personal),
      ('PMP Exam', 'Jun 30', AppColors.fasting),
      ('Debt <100K', 'Sep', AppColors.commute),
      ('10 Juz', 'Dec 31', AppColors.quran),
      ('Wedding', "Mar '27", AppColors.personal),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Milestones', onAction: null),
        const Gap(Spacing.xs),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: milestones.map((m) => _MilestoneChip(label: m.$1, date: m.$2, color: m.$3)).toList(),
        ),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.label, required this.date, required this.color});
  final String label, date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const Gap(6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              Text(date, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── RESOURCE PULSE ─────────────────────────────────────────────

class _ResourcePulse extends StatelessWidget {
  const _ResourcePulse({required this.scores});
  final ResourceScores scores;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Money', scores.money, AppColors.gold, Icons.account_balance_wallet_outlined),
      ('Time', scores.time, AppColors.cfi, Icons.schedule_outlined),
      ('Energy', scores.energy, AppColors.fasting, Icons.bolt_outlined),
      ('Health', scores.health, AppColors.deen, Icons.favorite_outline),
    ];

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Resource Pulse',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _overallColor(scores.overall).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${scores.overall}%',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _overallColor(scores.overall),
                  ),
                ),
              ),
            ],
          ),
          const Gap(Spacing.md),
          Row(
            children: items.map((item) {
              return Expanded(
                child: _PulseBar(
                  label: item.$1,
                  value: item.$2,
                  color: item.$3,
                  icon: item.$4,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _overallColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.gold;
    return AppColors.error;
  }
}

class _PulseBar extends StatelessWidget {
  const _PulseBar({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
          const Gap(6),
          SizedBox(
            height: 48,
            width: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: RotatedBox(
                quarterTurns: -1,
                child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const Gap(6),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 7,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SHARED HELPERS ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAction});
  final String title;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (onAction != null)
            GestureDetector(
              onTap: onAction,
              child: const Row(
                children: [
                  Text('See all', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.gold)),
                  Gap(2),
                  Icon(Icons.chevron_right, size: 14, color: AppColors.gold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.textMuted),
          const Gap(Spacing.xs),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
