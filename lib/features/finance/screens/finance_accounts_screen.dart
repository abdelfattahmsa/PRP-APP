import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class FinanceAccountsScreen extends StatelessWidget {
  const FinanceAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Accounts',
              subtitle: 'Your cash and bank accounts',
            ),
            const Gap(24),

            const SectionHeader('Balance'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Total Balance',
                value: '\$28,400',
                icon: Icons.account_balance_rounded,
                trend: '+\$420 this month',
                trendUp: true,
              ),
              StatCard(
                label: 'Cash on Hand',
                value: '\$4,200',
                subtitle: 'Checking account',
                icon: Icons.wallet_rounded,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Accounts', action: '+ Add'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Main Checking',
                subtitle: 'Bank · •••• 4521',
                value: '\$4,200',
                icon: Icons.account_balance_rounded,
                iconColor: AppColors.cfi,
              ),
              PlaceholderListItem(
                title: 'Savings Account',
                subtitle: 'Bank · •••• 7832',
                value: '\$22,800',
                icon: Icons.savings_rounded,
                iconColor: AppColors.success,
              ),
              PlaceholderListItem(
                title: 'Emergency Fund',
                subtitle: 'High-yield · •••• 1105',
                value: '\$1,400',
                icon: Icons.shield_rounded,
                iconColor: AppColors.warning,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Balance History', action: '6 months'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Total balance (\$)',
              data: const [22000, 23500, 24200, 25800, 26400, 27100, 28400],
            ),
          ],
        ),
      ),
    );
  }
}
