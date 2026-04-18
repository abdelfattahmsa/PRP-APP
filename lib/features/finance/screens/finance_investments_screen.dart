import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class FinanceInvestmentsScreen extends StatelessWidget {
  const FinanceInvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Investments',
              subtitle: 'Portfolio performance and holdings',
            ),
            const Gap(24),

            const SectionHeader('Portfolio'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Total Value',
                value: '\$16,800',
                icon: Icons.trending_up_rounded,
                trend: '+12.4% all time',
                trendUp: true,
              ),
              StatCard(
                label: 'YTD Return',
                value: '+\$1,840',
                subtitle: '+12.4%',
                icon: Icons.show_chart_rounded,
                trend: 'vs 8.2% index',
                trendUp: true,
              ),
              StatCard(
                label: 'Best Performer',
                value: 'VOO',
                subtitle: '+18.2% YTD',
                icon: Icons.star_rounded,
                iconColor: AppColors.gold,
              ),
              StatCard(
                label: 'Dividend Income',
                value: '\$240',
                subtitle: 'This year',
                icon: Icons.payments_rounded,
                iconColor: AppColors.success,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Performance', action: '1 Year'),
            const Gap(12),
            PlaceholderChart(
              height: 180,
              label: 'Portfolio value (\$)',
              data: const [14200, 13800, 15100, 14900, 16200, 15600, 16800],
            ),
            const Gap(24),

            const SectionHeader('Holdings', action: 'Manage'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Vanguard S&P 500 (VOO)',
                subtitle: '12 shares · Index Fund',
                value: '\$8,400',
                icon: Icons.bar_chart_rounded,
                iconColor: AppColors.pmp,
              ),
              PlaceholderListItem(
                title: 'Bitcoin (BTC)',
                subtitle: '0.12 BTC · Crypto',
                value: '\$5,200',
                icon: Icons.currency_bitcoin_rounded,
                iconColor: AppColors.warning,
              ),
              PlaceholderListItem(
                title: 'Apple Inc. (AAPL)',
                subtitle: '8 shares · Stock',
                value: '\$2,100',
                icon: Icons.smartphone_rounded,
                iconColor: AppColors.textSecondary,
              ),
              PlaceholderListItem(
                title: 'Emergency T-Bill',
                subtitle: '3-month · Bond',
                value: '\$1,100',
                icon: Icons.shield_rounded,
                iconColor: AppColors.cfi,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
