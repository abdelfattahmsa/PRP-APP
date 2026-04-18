import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class HealthFastingScreen extends StatelessWidget {
  const HealthFastingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Fasting',
              subtitle: 'Track your intermittent fasting window',
            ),
            const Gap(24),

            // Active fast timer card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Currently Fasting',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accent,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const Gap(16),
                  Text(
                    '14:22:08',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: -1,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Goal: 16:8 · End at 20:00',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: textSecondary),
                  ),
                  const Gap(20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 14.37 / 16,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 8,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    '14h 22m of 16h · 1h 38m remaining',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: textSecondary),
                  ),
                  const Gap(20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Stop Fast'),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Extend +1h'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(24),

            const SectionHeader('Stats'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Current Streak',
                value: '7 days',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.error,
                trend: 'Personal best!',
                trendUp: true,
              ),
              StatCard(
                label: 'Avg Window',
                value: '15.2h',
                subtitle: 'Last 7 days',
                icon: Icons.hourglass_bottom_rounded,
                iconColor: accent,
              ),
              StatCard(
                label: 'Longest Fast',
                value: '18h 40m',
                subtitle: '3 days ago',
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.gold,
              ),
              StatCard(
                label: 'Protocol',
                value: '16:8',
                subtitle: 'Current goal',
                icon: Icons.schedule_rounded,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Fasting History', action: '30 Days'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Fast duration (hours)',
              data: const [14.5, 16.0, 15.2, 16.8, 14.0, 17.5, 14.37],
            ),
            const Gap(24),

            const SectionHeader('Recent Fasts'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Today · In Progress',
                subtitle: 'Started 05:38 · 16:8 Protocol',
                value: '14h 22m',
                icon: Icons.hourglass_empty_rounded,
                iconColor: AppColors.warning,
              ),
              PlaceholderListItem(
                title: 'Yesterday · Completed',
                subtitle: 'Started 06:00 · 16:00 → 22:00',
                value: '16h 00m',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
              ),
              PlaceholderListItem(
                title: '2 days ago · Completed',
                subtitle: 'Started 05:20 · Extended',
                value: '18h 40m',
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.gold,
              ),
              PlaceholderListItem(
                title: '3 days ago · Completed',
                subtitle: 'Started 06:15',
                value: '15h 45m',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
