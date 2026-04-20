import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../engines/money/data/models/money_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chart.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/bottom_sheets.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

class FinanceOverviewScreen extends ConsumerWidget {
  const FinanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final summary = ref.watch(financeSummaryProvider);
    final banksAsync = ref.watch(bankAccountsProvider);
    final txAsync = ref.watch(transactionsProvider);

    final fmt = NumberFormat('#,##0', 'en_US');
    final netWorth =
        summary.totalSavings + summary.totalCurrent - summary.totalDebt;

    // 30-day spending by day (last 30 days)
    final spending30 = txAsync.value == null
        ? List.filled(30, 0.0)
        : () {
            final data = List.filled(30, 0.0);
            final now = DateTime.now();
            for (final tx in txAsync.value!.where((t) => !t.isIncome)) {
              final diff = now.difference(tx.date).inDays;
              if (diff >= 0 && diff < 30) data[29 - diff] += tx.amount;
            }
            return data;
          }();

    // 6-month net cashflow (income − expenses per month)
    final now = DateTime.now();
    final months6 = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      return m;
    });
    final monthLabels =
        months6.map((m) => _monthAbbr(m.month)).toList();
    final netCashflow = txAsync.value == null
        ? List.filled(6, 0.0)
        : months6.map((m) {
            final monthTxs = txAsync.value!.where((t) =>
                t.date.year == m.year && t.date.month == m.month);
            final inc =
                monthTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
            final exp =
                monthTxs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
            return inc - exp;
          }).toList();
    final cashflowColors = netCashflow
        .map((v) => v >= 0 ? AppColors.success : AppColors.error)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            const ScreenHeader(
              title: 'Finance',
              subtitle: 'Net worth & cash flow',
            ),
            const Gap(24),

            // ── KPI Grid ─────────────────────────────────────────
            BentoGrid(
              children: [
                BentoCell(
                  span: 2,
                  child: KpiCard(
                    label: 'Net Worth',
                    value: 'EGP ${fmt.format(netWorth)}',
                    icon: Icons.account_balance_rounded,
                    iconColor: AppColors.success,
                    subtitle:
                        'Savings: ${fmt.format(summary.totalSavings)} · Cash: ${fmt.format(summary.totalCurrent)}',
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: "Today's Spend",
                    value: 'EGP ${fmt.format(summary.todaySpend)}',
                    icon: Icons.shopping_bag_rounded,
                    iconColor: AppColors.error,
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Total Debt',
                    value: 'EGP ${fmt.format(summary.totalDebt)}',
                    icon: Icons.credit_card_rounded,
                    iconColor: AppColors.warning,
                    subtitle: summary.totalCC > 0
                        ? 'CC: ${fmt.format(summary.totalCC)}'
                        : null,
                  ),
                ),
              ],
            ),
            const Gap(20),

            // ── 30-day Spending Chart ─────────────────────────────
            ChartCard(
              title: '30-Day Spending',
              height: 140,
              child: txAsync.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : AppLineChart(
                      data: spending30,
                      color: AppColors.error,
                      showGradient: true,
                    ),
            ),
            const Gap(20),

            // ── 6-Month Net Cashflow ──────────────────────────────
            ChartCard(
              title: '6-Month Net Cashflow',
              height: 140,
              child: txAsync.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : AppBarChart(
                      data: netCashflow,
                      labels: monthLabels,
                      colors: cashflowColors,
                    ),
            ),
            const Gap(20),

            // ── Spending by Category ──────────────────────────────
            if ((txAsync.value ?? []).where((t) => !t.isIncome).isNotEmpty)
              _SpendingDonut(transactions: txAsync.value!),
            if ((txAsync.value ?? []).where((t) => !t.isIncome).isNotEmpty)
              const Gap(20),

            // ── Accounts ─────────────────────────────────────────
            BentoSectionHeader(
              'Accounts',
              action: TextButton(
                onPressed: () => context.go(Routes.financeAccounts),
                child:
                    const Text('All', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            banksAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load accounts'),
              data: (banks) {
                if (banks.isEmpty) {
                  return const EmptyState(
                    message: 'No accounts added yet',
                    icon: Icons.account_balance_outlined,
                    compact: true,
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < banks.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        _AccountTile(
                            bank: banks[i],
                            textSecondary: textSecondary),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Gap(20),

            // ── Recent Transactions ───────────────────────────────
            BentoSectionHeader(
              'Recent Transactions',
              action: TextButton(
                onPressed: () => context.go(Routes.financeTransactions),
                child:
                    const Text('All', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            txAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load transactions'),
              data: (txs) {
                final recent = [...txs]
                  ..sort((a, b) => b.date.compareTo(a.date));
                final visible = recent.take(5).toList();
                if (visible.isEmpty) {
                  return EmptyState(
                    message: 'No transactions yet',
                    icon: Icons.receipt_long_outlined,
                    compact: true,
                    action: TextButton(
                      onPressed: () => showAddTransaction(context),
                      child: const Text('Add first transaction'),
                    ),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < visible.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        _RecentTxTile(
                            tx: visible[i],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransaction(context),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

String _monthAbbr(int month) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return m[(month - 1).clamp(0, 11)];
}

class _SpendingDonut extends StatelessWidget {
  const _SpendingDonut({required this.transactions});
  final List<Transaction> transactions;

  static const _catColors = {
    'Food': AppColors.fasting,
    'Transport': AppColors.pmp,
    'Shopping': AppColors.fasting,
    'Health': AppColors.health,
    'Entertainment': AppColors.kyberia,
    'Bills': AppColors.warning,
    'Education': AppColors.gold,
    'Personal': AppColors.rest,
    'Investment': AppColors.success,
    'Other': AppColors.textSecondary,
    'General': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = transactions.where((t) =>
        !t.isIncome && now.difference(t.date).inDays < 30).toList();

    final Map<String, double> byCategory = {};
    for (final tx in expenses) {
      byCategory[tx.category] =
          (byCategory[tx.category] ?? 0) + tx.amount;
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final defaultColors = [
      AppColors.error, AppColors.warning, AppColors.pmp,
      AppColors.kyberia, AppColors.cfi, AppColors.health,
    ];

    final slices = sorted.asMap().entries.map((e) {
      final color = _catColors[e.value.key] ??
          defaultColors[e.key % defaultColors.length];
      return DonutSlice(label: e.value.key, value: e.value.value, color: color);
    }).toList();

    return ChartCard(
      title: 'Spending by Category (30d)',
      height: 160,
      child: AppDonutChart(
        slices: slices,
        size: 130,
        strokeWidth: 20,
        centerLabel: 'Tap\nslice',
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.bank, required this.textSecondary});
  final BankAccount bank;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final total =
        bank.currentBalance + bank.savingsBalance - bank.creditCardBalance;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_rounded,
                size: 18, color: AppColors.success),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (bank.creditCardLimit > 0)
                  Text(
                    'CC: ${fmt.format(bank.creditCardBalance)} / ${fmt.format(bank.creditCardLimit)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontFamily: 'IBMPlexMono'),
                  ),
              ],
            ),
          ),
          Text(
            'EGP ${fmt.format(total)}',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: total >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTxTile extends StatelessWidget {
  const _RecentTxTile({required this.tx, required this.textSecondary});
  final Transaction tx;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (tx.isIncome ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tx.isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 14,
              color: tx.isIncome ? AppColors.success : AppColors.error,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500)),
                Text(tx.category,
                    style: TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                        fontFamily: 'IBMPlexMono')),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '−'}${fmt.format(tx.amount)}',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tx.isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
