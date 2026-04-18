import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class FinanceLiabilitiesScreen extends StatelessWidget {
  const FinanceLiabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Liabilities',
              subtitle: 'Debts and obligations',
            ),
            const Gap(24),

            const SectionHeader('Overview'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Total Debt',
                value: '\$8,400',
                icon: Icons.trending_down_rounded,
                iconColor: AppColors.error,
                trend: '−\$420 this month',
                trendUp: true,
              ),
              StatCard(
                label: 'Monthly Payment',
                value: '\$420',
                subtitle: 'Minimum required',
                icon: Icons.calendar_month_rounded,
              ),
              StatCard(
                label: 'Debt-to-Income',
                value: '11%',
                subtitle: 'Healthy < 20%',
                icon: Icons.percent_rounded,
                iconColor: AppColors.success,
              ),
              StatCard(
                label: 'Payoff Date',
                value: 'Jan 26',
                subtitle: 'At current pace',
                icon: Icons.flag_rounded,
                iconColor: AppColors.success,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Payoff Projection', action: 'Accelerate'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Remaining debt (\$)',
              data: const [8400, 7980, 7560, 7140, 6720, 6300, 5880],
            ),
            const Gap(24),

            const SectionHeader('Debts', action: '+ Add'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Student Loan',
                subtitle: 'Due 15th · 4.5% APR',
                value: '\$6,200',
                valueColor: AppColors.error,
                icon: Icons.school_rounded,
                iconColor: AppColors.pmp,
              ),
              PlaceholderListItem(
                title: 'Credit Card',
                subtitle: 'Due 22nd · 19.9% APR',
                value: '\$1,400',
                valueColor: AppColors.error,
                icon: Icons.credit_card_rounded,
                iconColor: AppColors.error,
              ),
              PlaceholderListItem(
                title: 'Personal Loan',
                subtitle: 'Due 1st · 7.2% APR',
                value: '\$800',
                valueColor: AppColors.error,
                icon: Icons.handshake_rounded,
                iconColor: AppColors.warning,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
