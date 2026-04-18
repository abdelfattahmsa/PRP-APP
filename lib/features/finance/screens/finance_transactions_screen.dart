import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class FinanceTransactionsScreen extends StatelessWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Transactions',
              subtitle: 'Your spending history',
            ),
            const Gap(24),

            const SectionHeader('This Period'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'This Week',
                value: '−\$340',
                icon: Icons.today_rounded,
                trend: '+\$42 vs last week',
                trendUp: false,
              ),
              StatCard(
                label: 'This Month',
                value: '−\$2,100',
                subtitle: '44 transactions',
                icon: Icons.date_range_rounded,
              ),
            ]),
            const Gap(24),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search transactions…',
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  filled: false,
                ),
              ),
            ),
            const Gap(20),

            const SectionHeader('Today'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Grocery Shopping',
                subtitle: '14:32 · Food',
                value: '−\$48.50',
                valueColor: AppColors.error,
                icon: Icons.shopping_basket_rounded,
                iconColor: AppColors.warning,
              ),
              PlaceholderListItem(
                title: 'Coffee Shop',
                subtitle: '08:15 · Food & Drink',
                value: '−\$6.40',
                valueColor: AppColors.error,
                icon: Icons.local_cafe_rounded,
                iconColor: AppColors.cfi,
              ),
            ]),
            const Gap(20),

            const SectionHeader('Yesterday'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Salary',
                subtitle: '09:00 · Income',
                value: '+\$3,800',
                valueColor: AppColors.success,
                icon: Icons.payments_rounded,
                iconColor: AppColors.success,
              ),
              PlaceholderListItem(
                title: 'Electricity Bill',
                subtitle: '11:00 · Bills',
                value: '−\$95.00',
                valueColor: AppColors.error,
                icon: Icons.bolt_rounded,
                iconColor: AppColors.warning,
              ),
              PlaceholderListItem(
                title: 'Online Transfer',
                subtitle: '15:45 · Transfer',
                value: '−\$500',
                valueColor: AppColors.error,
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.pmp,
              ),
            ]),
            const Gap(20),

            const SectionHeader('This Week'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Gym Membership',
                subtitle: '3 days ago · Health',
                value: '−\$35.00',
                valueColor: AppColors.error,
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.health,
              ),
              PlaceholderListItem(
                title: 'Restaurant Dinner',
                subtitle: '4 days ago · Food',
                value: '−\$62.80',
                valueColor: AppColors.error,
                icon: Icons.restaurant_rounded,
                iconColor: AppColors.fasting,
              ),
              PlaceholderListItem(
                title: 'Transport',
                subtitle: '5 days ago · Transport',
                value: '−\$18.50',
                valueColor: AppColors.error,
                icon: Icons.directions_car_rounded,
                iconColor: AppColors.commute,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
