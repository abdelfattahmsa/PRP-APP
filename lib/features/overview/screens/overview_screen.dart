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

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});
  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  late final _clock = Stream.periodic(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final habits    = ref.watch(habitsTodayProvider);
    final summary   = ref.watch(financeSummaryProvider);
    final goals     = ref.watch(goalsProvider).value ?? [];
    final sessions  = ref.watch(focusSessionsProvider).value ?? [];
    final calEvents = ref.watch(calendarProvider).value ?? [];
    final schedMode = 'normal'; // could read from prefs

    // Today focus time
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayMins = sessions
        .where((s) => DateFormat('yyyy-MM-dd').format(s.date) == todayKey && s.completed)
        .fold(0, (sum, s) => sum + s.actualMinutes);

    // Current schedule block
    final schedAsync = ref.watch(scheduleProvider(schedMode));
    final blocks = schedAsync.value ?? [];
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    ScheduleBlock? curBlock;
    ScheduleBlock? nextBlock;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final nextMins = i + 1 < blocks.length ? blocks[i + 1].minutesSinceMidnight : 24 * 60;
      if (nowMins >= b.minutesSinceMidnight && nowMins < nextMins) {
        curBlock = b;
        if (i + 1 < blocks.length) nextBlock = blocks[i + 1];
        break;
      }
    }

    // Upcoming events
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = calEvents
        .where((e) => !e.isDone && DateTime(e.date.year, e.date.month, e.date.day).compareTo(today) >= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final activeGoals = goals.where((g) => g.status == 'active').toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with greeting
          SliverAppBar(
            expandedHeight: 120,
            floating: true, snap: true, pinned: false,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0F0B1C), AppColors.bg],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StreamBuilder(
                      stream: _clock,
                      builder: (ctx, _) => Text(
                        DateFormat('HH:mm:ss').format(DateTime.now()),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.gold),
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Current block
                if (curBlock != null) _CurrentBlock(block: curBlock, nextBlock: nextBlock)
                    .animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
                const Gap(12),

                // Quick stats row
                Row(children: [
                  Expanded(child: _QuickStat(label: 'Habits', value: '${habits.done}/${habits.total}', color: habits.pct == 1.0 ? AppColors.deen : AppColors.gold, icon: Icons.check_circle_outline, onTap: () => context.go(Routes.habits))),
                  const Gap(8),
                  Expanded(child: _QuickStat(label: 'Focus', value: '${todayMins}m', color: AppColors.pmp, icon: Icons.timer_outlined, onTap: () => context.go(Routes.focus))),
                  const Gap(8),
                  Expanded(child: _QuickStat(label: 'Goals', value: '${activeGoals.length}', color: AppColors.kyberia, icon: Icons.flag_outlined, onTap: () => context.go(Routes.goals))),
                ]).animate(delay: 100.ms).fadeIn(duration: 300.ms),
                const Gap(8),
                Row(children: [
                  Expanded(child: _QuickStat(label: 'CC Debt', value: 'EGP ${_fmt(summary.totalCC)}', color: AppColors.error, icon: Icons.credit_card, onTap: () => context.go(Routes.finance))),
                  const Gap(8),
                  Expanded(child: _QuickStat(label: 'Savings', value: 'EGP ${_fmt(summary.totalSavings)}', color: AppColors.gold, icon: Icons.savings_outlined, onTap: () => context.go(Routes.finance))),
                  const Gap(8),
                  Expanded(child: _QuickStat(label: 'Rem. Limit', value: 'EGP ${_fmt(summary.remainingLimit)}', color: summary.remainingLimit < 0 ? AppColors.error : AppColors.deen, icon: Icons.account_balance_outlined, onTap: () => context.go(Routes.finance))),
                ]).animate(delay: 150.ms).fadeIn(duration: 300.ms),
                const Gap(16),

                // Upcoming events
                _SectionTitle(title: 'Upcoming Events', action: 'See all', onAction: () => context.go(Routes.calendar)),
                ...upcoming.take(5).map((ev) {
                  final color = AppColors.categoryColor(ev.typeKey);
                  final daysAway = ev.date.difference(today).inDays;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(9), border: Border.all(color: color.withOpacity(0.25))),
                    child: Row(children: [
                      Container(width: 3, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const Gap(10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ev.title, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(DateFormat('d MMM yyyy').format(ev.date), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: AppColors.textSecondary)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: Text(daysAway == 0 ? 'Today' : daysAway == 1 ? 'Tomorrow' : '${daysAway}d', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  );
                }),

                if (upcoming.isEmpty) const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No upcoming events', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13)),
                ),
                const Gap(16),

                // Top goals
                _SectionTitle(title: 'Active Goals', action: 'See all', onAction: () => context.go(Routes.goals)),
                ...activeGoals.take(4).map((g) {
                  final pColor = g.priority == 'high' ? AppColors.error : g.priority == 'medium' ? AppColors.gold : AppColors.deen;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: Text(g.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          Text('${g.progress}%', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: pColor, fontWeight: FontWeight.w600)),
                        ]),
                        const Gap(6),
                        ClipRRect(borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(value: g.progress / 100, minHeight: 4, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(pColor))),
                        const Gap(4),
                        Row(children: [
                          Text(DateFormat('d MMM yy').format(g.targetDate), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
                          const Spacer(),
                          Text(g.daysRemaining < 0 ? 'Overdue' : '${g.daysRemaining}d left', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: g.daysRemaining < 0 ? AppColors.error : AppColors.textSecondary)),
                        ]),
                      ]),
                    ),
                  );
                }),
                const Gap(16),

                // Milestone strip
                _SectionTitle(title: '2026 Milestones', action: null, onAction: null),
                const Gap(6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final m in [
                    ('🚀 Product #1', 'Apr 10', AppColors.error),
                    ('💼 1st Client', 'May 1',  AppColors.kyberia),
                    ('💍 Engaged',    'May 30', AppColors.personal),
                    ('📋 PMP Exam',   '≤ Jun 30', AppColors.fasting),
                    ('📉 Debt ≤100K', 'Sep',    AppColors.commute),
                    ('📖 10 Juz',     'Dec 31', AppColors.quran),
                    ('💒 Wedding',    'Mar \'27', AppColors.personal),
                  ]) _MilestoneChip(label: m.$1, date: m.$2, color: m.$3),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final n = NumberFormat('#,##0', 'en');
    return n.format(v);
  }
}

class _CurrentBlock extends StatelessWidget {
  const _CurrentBlock({required this.block, this.nextBlock});
  final dynamic block;
  final dynamic nextBlock;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(block.categoryKey);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.12), AppColors.card], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.4))),
            child: Text('NOW · ${block.time}', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: color, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)])),
        ]),
        const Gap(8),
        Text(block.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        if (block.note != null) ...[const Gap(3), Text(block.note!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic))],
        if (nextBlock != null) ...[
          const Gap(6),
          Text('Next: ${nextBlock!.time} · ${nextBlock!.label}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.label, required this.value, required this.color, required this.icon, this.onTap});
  final String label, value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 13, color: AppColors.textSecondary), const Gap(4), Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary))]),
        const Gap(4),
        Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay', fontSize: 16)),
      const Spacer(),
      if (action != null && onAction != null)
        GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.gold))),
    ]),
  );
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.label, required this.date, required this.color});
  final String label, date;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      Text(date,  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
    ]),
  );
}
