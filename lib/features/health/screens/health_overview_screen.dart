import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class HealthOverviewScreen extends StatelessWidget {
  const HealthOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Health',
              subtitle: 'Vitals, habits, and daily wellness',
            ),
            const Gap(24),

            const SectionHeader('Today'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Steps',
                value: '8,240',
                subtitle: '82% of 10k goal',
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.health,
                trend: '+1,200 vs avg',
                trendUp: true,
              ),
              StatCard(
                label: 'Sleep',
                value: '7.2h',
                subtitle: 'Good quality',
                icon: Icons.bedtime_rounded,
                iconColor: AppColors.kyberia,
                trend: '+0.5h vs avg',
                trendUp: true,
              ),
              StatCard(
                label: 'Water',
                value: '6 / 8',
                subtitle: 'Glasses today',
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.cfi,
              ),
              StatCard(
                label: 'Health Score',
                value: '72',
                subtitle: 'Out of 100',
                icon: Icons.favorite_rounded,
                iconColor: AppColors.error,
                trend: '+3 vs last week',
                trendUp: true,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Weekly Score', action: '4 Weeks'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Health score',
              data: const [65, 68, 70, 67, 72, 71, 72],
            ),
            const Gap(24),

            const SectionHeader('Metrics'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Active Calories',
                subtitle: 'Target: 500 kcal',
                value: '384 kcal',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.fasting,
              ),
              PlaceholderListItem(
                title: 'Heart Rate',
                subtitle: 'Resting',
                value: '68 bpm',
                icon: Icons.monitor_heart_rounded,
                iconColor: AppColors.error,
              ),
              PlaceholderListItem(
                title: 'Weight',
                subtitle: 'Logged today',
                value: '78.4 kg',
                icon: Icons.scale_rounded,
                iconColor: AppColors.health,
              ),
              PlaceholderListItem(
                title: 'BMI',
                subtitle: 'Normal range',
                value: '24.1',
                icon: Icons.person_rounded,
                iconColor: AppColors.success,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
