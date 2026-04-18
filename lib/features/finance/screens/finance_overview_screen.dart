import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class FinanceOverviewScreen extends StatelessWidget {
  const FinanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Finance',
              subtitle: 'Your financial dashboard',
            ),
            const Gap(24),

            const SectionHeader('Summary'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Net Worth',
                value: '\$45,200',
                subtitle: 'Total assets − debts',
                icon: Icons.account_balance_rounded,
                trend: '+\$1,240 this month',
                trendUp: true,
              ),
              StatCard(
                label: 'Monthly Income',
                value: '\$3,800',
                subtitle: 'After tax',
                icon: Icons.payments_rounded,
                trend: 'Stable',
                trendUp: true,
              ),
              StatCard(
                label: 'Expenses',
                value: '\$2,100',
                subtitle: 'This month',
                icon: Icons.receipt_long_rounded,
                trend: '+\$180 vs last month',
                trendUp: false,
              ),
              StatCard(
                label: 'Savings Rate',
                value: '44.7%',
                subtitle: '\$1,700 saved',
                icon: Icons.savings_rounded,
                trend: '+2.1% vs avg',
                trendUp: true,
              ),
            ]),
            const Gap(24),

            const SectionHeader('30-Day Spending', action: 'All time'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Daily spend (\$)',
              data: const [42, 85, 30, 120, 65, 48, 200, 55, 40, 90,
                           70, 35, 55, 80, 45, 62, 95, 50, 38, 75,
                           88, 42, 110, 60, 45, 70, 55, 80, 48, 65],
            ),
            const Gap(24),

            const SectionHeader('Budget Status'),
            const Gap(12),
            _BudgetStatus(),
            const Gap(24),

            const SectionHeader('Recent Transactions', action: 'See all'),
            const Gap(12),
            PlaceholderList(items: [
              PlaceholderListItem(
                title: 'Grocery Shopping',
                subtitle: 'Today · Food',
                value: '−\$48.50',
                valueColor: AppColors.error,
                icon: Icons.shopping_cart_rounded,
                iconColor: AppColors.warning,
              ),
              PlaceholderListItem(
                title: 'Salary Transfer',
                subtitle: 'Yesterday · Income',
                value: '+\$3,800',
                valueColor: AppColors.success,
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.success,
              ),
              PlaceholderListItem(
                title: 'Electricity Bill',
                subtitle: '2 days ago · Bills',
                value: '−\$95.00',
                valueColor: AppColors.error,
                icon: Icons.bolt_rounded,
                iconColor: AppColors.warning,
              ),
              PlaceholderListItem(
                title: 'Coffee & Snacks',
                subtitle: '2 days ago · Food',
                value: '−\$12.80',
                valueColor: AppColors.error,
                icon: Icons.local_cafe_rounded,
                iconColor: AppColors.cfi,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BudgetStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    const budgets = [
      ('Food', 0.62, '\$310 / \$500'),
      ('Transport', 0.40, '\$80 / \$200'),
      ('Bills', 0.95, '\$475 / \$500'),
      ('Shopping', 0.28, '\$140 / \$500'),
      ('Health', 0.50, '\$75 / \$150'),
    ];

    return Container(
      padding: const EdgeInsets.all(Spacing.base),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: budgets.map((b) {
          final color = b.$2 > 0.9
              ? AppColors.error
              : b.$2 > 0.7
                  ? AppColors.warning
                  : AppColors.accent;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.$1,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text(b.$3,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: textSecondary)),
                  ],
                ),
                const Gap(4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: b.$2,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
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
