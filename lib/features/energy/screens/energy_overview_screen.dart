import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chart.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

class EnergyOverviewScreen extends ConsumerWidget {
  const EnergyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final sessAsync = ref.watch(focusSessionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 7-day focus minutes
    final days7 = List.generate(
        7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    final dayLabels = days7
        .map((d) => DateFormat('EEE').format(d).substring(0, 1))
        .toList();

    final focusData = sessAsync.value == null
        ? List.filled(7, 0.0)
        : days7.map((day) {
            final key = DateFormat('yyyy-MM-dd').format(day);
            return sessAsync.value!
                .where((s) =>
                    s.completed &&
                    DateFormat('yyyy-MM-dd').format(s.date) == key)
                .fold(0.0, (s, sess) => s + sess.actualMinutes);
          }).toList();

    final sessions = sessAsync.value ?? [];
    final todayMins = sessions
        .where((s) =>
            s.completed &&
            DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
        .fold(0, (s, sess) => s + sess.actualMinutes);
    final totalMins =
        sessions.where((s) => s.completed).fold(0, (s, sess) => s + sess.actualMinutes);
    final todayCount = sessions
        .where((s) => DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
        .length;

    final goals = goalsAsync.value ?? [];
    final activeGoals = goals.where((g) => g.status == 'active').toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Energy',
              subtitle: 'Focus, goals & productivity',
            ),
            const Gap(24),

            // ── KPI Grid ─────────────────────────────────────────
            BentoGrid(
              children: [
                BentoCell(
                  child: KpiCard(
                    label: 'Focus Today',
                    value: '${todayMins}m',
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.warning,
                    subtitle: '$todayCount sessions',
                    onTap: () => context.go(Routes.energyFocus),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Total Focus',
                    value: '${totalMins}m',
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.gold,
                    subtitle: '${sessions.length} sessions',
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Active Goals',
                    value: '${activeGoals.length}',
                    icon: Icons.flag_rounded,
                    iconColor: AppColors.pmp,
                    onTap: () => context.go(Routes.energyGoals),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Goals Done',
                    value:
                        '${goals.where((g) => g.status == 'done').length}',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const Gap(20),

            // ── 7-day Focus Chart ─────────────────────────────────
            ChartCard(
              title: '7-Day Focus (min)',
              height: 140,
              action: TextButton(
                onPressed: () => context.go(Routes.energyFocus),
                child: const Text('Timer', style: TextStyle(fontSize: 12)),
              ),
              child: sessAsync.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : AppBarChart(data: focusData, labels: dayLabels),
            ),
            const Gap(20),

            // ── Recent Sessions ───────────────────────────────────
            BentoSectionHeader(
              'Recent Sessions',
              action: TextButton(
                onPressed: () => context.go(Routes.energyFocus),
                child: const Text('All', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            sessAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load sessions'),
              data: (sess) {
                final recent = sess.take(5).toList();
                if (recent.isEmpty) {
                  return EmptyState(
                    message: 'No focus sessions yet',
                    icon: Icons.timer_outlined,
                    compact: true,
                    action: TextButton(
                      onPressed: () => context.go(Routes.energyFocus),
                      child: const Text('Start a session'),
                    ),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < recent.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        _SessionTile(
                            session: recent[i],
                            textSecondary: textSecondary),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Gap(20),

            // ── Active Goals ──────────────────────────────────────
            BentoSectionHeader(
              'Goals',
              action: TextButton(
                onPressed: () => context.go(Routes.energyGoals),
                child: const Text('All', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            goalsAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load goals'),
              data: (goals) {
                if (activeGoals.isEmpty) {
                  return const EmptyState(
                    message: 'No active goals',
                    icon: Icons.flag_outlined,
                    compact: true,
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < activeGoals.take(4).length;
                          i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        Padding(
                          padding: const EdgeInsets.all(Spacing.base),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _PriorityDot(
                                      priority: activeGoals[i].priority),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      activeGoals[i].title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '${activeGoals[i].progress}%',
                                    style: TextStyle(
                                      fontFamily: 'IBMPlexMono',
                                      fontSize: 12,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: activeGoals[i].progress / 100,
                                  minHeight: 4,
                                  backgroundColor: isDark
                                      ? AppColors.border
                                      : AppColors.lightBorder,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(
      {required this.session, required this.textSecondary});
  final dynamic session;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(session.blockCategoryKey);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.blockLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text(
                  DateFormat('d MMM · HH:mm').format(session.date),
                  style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontFamily: 'IBMPlexMono'),
                ),
              ],
            ),
          ),
          Text(
            '${session.actualMinutes}m',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: session.completed ? AppColors.success : textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = priority == 'high'
        ? AppColors.error
        : priority == 'medium'
            ? AppColors.warning
            : AppColors.textMuted;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
