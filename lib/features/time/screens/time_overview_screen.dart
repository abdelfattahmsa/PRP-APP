import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chart.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

class TimeOverviewScreen extends ConsumerWidget {
  const TimeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final scheduleAsync = ref.watch(scheduleProvider('normal'));
    final sessAsync = ref.watch(focusSessionsProvider);
    final calAsync = ref.watch(calendarProvider);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 7-day focus data
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

    final todayFocusMins = sessAsync.value == null
        ? 0
        : sessAsync.value!
            .where((s) =>
                s.completed &&
                DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
            .fold(0, (s, sess) => s + sess.actualMinutes);

    final todayEvents = calAsync.value
            ?.where((e) =>
                DateFormat('yyyy-MM-dd').format(e.date) == todayStr)
            .toList() ??
        [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Time',
              subtitle: 'Plan and track your daily time',
            ),
            const Gap(24),

            // ── KPI Grid ──────────────────────────────────────────
            BentoGrid(
              children: [
                BentoCell(
                  child: KpiCard(
                    label: 'Focus Today',
                    value: '${todayFocusMins}m',
                    icon: Icons.psychology_rounded,
                    iconColor: AppColors.accent,
                    subtitle:
                        '${sessAsync.value?.where((s) => s.completed && DateFormat('yyyy-MM-dd').format(s.date) == todayStr).length ?? 0} sessions',
                    onTap: () => context.go(Routes.energyFocus),
                  ),
                ),
                BentoCell(
                  child: scheduleAsync.when(
                    loading: () => const KpiCard(
                      label: 'Blocks',
                      value: '—',
                      icon: Icons.view_timeline_outlined,
                      iconColor: AppColors.gold,
                    ),
                    error: (_, __) => const KpiCard(
                      label: 'Blocks',
                      value: '—',
                      icon: Icons.view_timeline_outlined,
                      iconColor: AppColors.gold,
                    ),
                    data: (blocks) => KpiCard(
                      label: 'Blocks',
                      value: '${blocks.length}',
                      icon: Icons.view_timeline_outlined,
                      iconColor: AppColors.gold,
                      subtitle: 'in schedule',
                      onTap: () => context.go(Routes.timeSchedule),
                    ),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Events Today',
                    value: '${todayEvents.length}',
                    icon: Icons.event_rounded,
                    iconColor: AppColors.info,
                    onTap: () => context.go(Routes.timeCalendar),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Focus 7d',
                    value: '${focusData.fold(0.0, (a, b) => a + b).round()}m',
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.pmp,
                  ),
                ),
              ],
            ),
            const Gap(20),

            // ── 7-day Focus Chart ─────────────────────────────────
            ChartCard(
              title: '7-Day Focus (min)',
              height: 130,
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

            // ── Schedule Allocation ───────────────────────────────
            if (scheduleAsync.hasValue && scheduleAsync.value!.isNotEmpty) ...[
              Builder(builder: (_) {
                final blocks = scheduleAsync.value!;
                final Map<String, int> countByCategory = {};
                for (final b in blocks) {
                  countByCategory[b.categoryKey] =
                      (countByCategory[b.categoryKey] ?? 0) + 1;
                }
                final sorted = countByCategory.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final slices = sorted.map((e) => DonutSlice(
                      label: categoryInfoMap[e.key]?.label ?? e.key,
                      value: e.value.toDouble(),
                      color: AppColors.categoryColor(e.key),
                    )).toList();
                return ChartCard(
                  title: 'Schedule Allocation',
                  height: 160,
                  child: AppDonutChart(
                    slices: slices,
                    size: 130,
                    strokeWidth: 20,
                    centerLabel: '${blocks.length}\nblocks',
                  ),
                );
              }),
              const Gap(20),
            ],

            // ── Today's Schedule ──────────────────────────────────
            BentoSectionHeader(
              "Today's Schedule",
              action: TextButton(
                onPressed: () => context.go(Routes.timeSchedule),
                child: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            scheduleAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load schedule'),
              data: (blocks) {
                if (blocks.isEmpty) {
                  return EmptyState(
                    message: 'No schedule blocks yet',
                    icon: Icons.view_timeline_outlined,
                    compact: true,
                    action: TextButton(
                      onPressed: () => context.go(Routes.timeSchedule),
                      child: const Text('Set up schedule'),
                    ),
                  );
                }
                final sorted = [...blocks]
                  ..sort((a, b) => a.time.compareTo(b.time));
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < sorted.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        _BlockTile(
                            block: sorted[i],
                            textSecondary: textSecondary),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Gap(20),

            // ── Today's Events ────────────────────────────────────
            BentoSectionHeader(
              "Today's Events",
              action: TextButton(
                onPressed: () => context.go(Routes.timeCalendar),
                child:
                    const Text('Calendar', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            calAsync.when(
              loading: () => const LoadingCard(height: 60),
              error: (_, __) =>
                  const ErrorState(message: 'Could not load events'),
              data: (_) {
                if (todayEvents.isEmpty) {
                  return const EmptyState(
                    message: 'No events today',
                    icon: Icons.event_outlined,
                    compact: true,
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < todayEvents.length;
                          i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        _EventTile(
                            event: todayEvents[i],
                            textSecondary: textSecondary),
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

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block, required this.textSecondary});
  final dynamic block;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(block.categoryKey as String);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.label as String,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  block.time as String,
                  style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontFamily: 'Roboto'),
                ),
              ],
            ),
          ),
          if ((block.duration as String?) != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                block.duration as String,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.textSecondary});
  final dynamic event;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(
        (event.typeKey as String?) ?? 'personal');
    final isDone = (event.isDone as bool?) ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isDone ? AppColors.textMuted : color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              event.title as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? textSecondary : null,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}