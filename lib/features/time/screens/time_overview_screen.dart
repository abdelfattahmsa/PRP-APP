import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class TimeOverviewScreen extends StatelessWidget {
  const TimeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

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

            const SectionHeader('Today'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Scheduled',
                value: '6.5h',
                subtitle: 'of 12h available',
                icon: Icons.schedule_rounded,
                trend: '+1h vs yesterday',
                trendUp: true,
              ),
              StatCard(
                label: 'Free Time',
                value: '5.5h',
                subtitle: 'unscheduled',
                icon: Icons.hourglass_empty_rounded,
              ),
              StatCard(
                label: 'Productivity',
                value: '78%',
                subtitle: 'on-track blocks',
                icon: Icons.trending_up_rounded,
                trend: '+6% vs avg',
                trendUp: true,
              ),
              StatCard(
                label: 'Deep Work',
                value: '2.5h',
                subtitle: 'focused sessions',
                icon: Icons.psychology_rounded,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Time Allocation', action: 'This week'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Hours per day',
              data: const [5.5, 7.0, 6.5, 8.0, 6.0, 9.0, 7.5],
            ),
            const Gap(24),

            const SectionHeader("Today's Blocks", action: 'See all'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Morning Deep Work',
                subtitle: '06:00 — 08:00 · Deen',
                value: '2h',
                icon: Icons.self_improvement_rounded,
                iconColor: AppColors.deen,
              ),
              PlaceholderListItem(
                title: 'PMP Study Session',
                subtitle: '09:00 — 11:00 · Study',
                value: '2h',
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.pmp,
              ),
              PlaceholderListItem(
                title: 'Work Block',
                subtitle: '12:00 — 17:00 · Work',
                value: '5h',
                icon: Icons.work_rounded,
                iconColor: AppColors.work,
              ),
              PlaceholderListItem(
                title: 'Health & Fitness',
                subtitle: '18:00 — 19:00 · Health',
                value: '1h',
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.health,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Category Breakdown'),
            const Gap(12),
            _CategoryBreakdown(isDark: isDark, textSecondary: textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown(
      {required this.isDark, required this.textSecondary});
  final bool isDark;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    const cats = [
      ('Work', AppColors.work, 0.35),
      ('Deen', AppColors.deen, 0.18),
      ('Study', AppColors.pmp, 0.15),
      ('Health', AppColors.health, 0.12),
      ('Rest', AppColors.rest, 0.10),
      ('Other', AppColors.commute, 0.10),
    ];

    return Container(
      padding: const EdgeInsets.all(Spacing.base),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: cats.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cat.$2,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(10),
                SizedBox(
                  width: 56,
                  child: Text(
                    cat.$1,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: cat.$3,
                      backgroundColor:
                          cat.$2.withValues(alpha: 0.1),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(cat.$2),
                      minHeight: 6,
                    ),
                  ),
                ),
                const Gap(10),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(cat.$3 * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: textSecondary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
