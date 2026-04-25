import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/money/data/models/money_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/bottom_sheets.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

class FinanceTransactionsScreen extends ConsumerStatefulWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  ConsumerState<FinanceTransactionsScreen> createState() =>
      _FinanceTransactionsScreenState();
}

class _FinanceTransactionsScreenState
    extends ConsumerState<FinanceTransactionsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: txAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => ErrorState(
              message: 'Failed to load transactions',
              onRetry: () => ref.invalidate(transactionsProvider)),
          data: (allTx) {
            final fmt = NumberFormat('#,##0.##', 'en_US');

            var filtered = allTx.where((t) {
              final q = _query.toLowerCase();
              if (q.isEmpty) return true;
              return t.description.toLowerCase().contains(q) ||
                  t.category.toLowerCase().contains(q);
            }).toList();
            filtered.sort((a, b) => b.date.compareTo(a.date));

            final totalIncome = allTx
                .where((t) => t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);
            final totalExpense = allTx
                .where((t) => !t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);

            final groups = <String, List<Transaction>>{};
            for (final tx in filtered) {
              final key = DateFormat('dd MMM yyyy').format(tx.date);
              groups.putIfAbsent(key, () => []).add(tx);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenHeader(
                        title: 'Transactions',
                        subtitle: 'Income & expenses log',
                      ),
                      const Gap(16),
                      BentoGrid(
                        children: [
                          BentoCell(
                            child: KpiCard(
                              label: 'Income',
                              value: 'EGP ${fmt.format(totalIncome)}',
                              icon: Icons.arrow_downward_rounded,
                              iconColor: AppColors.success,
                            ),
                          ),
                          BentoCell(
                            child: KpiCard(
                              label: 'Expenses',
                              value: 'EGP ${fmt.format(totalExpense)}',
                              icon: Icons.arrow_upward_rounded,
                              iconColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search transactions…',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const Gap(12),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          message: _query.isNotEmpty
                              ? 'No results for "$_query"'
                              : 'No transactions yet',
                          icon: Icons.receipt_long_outlined,
                          compact: true,
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: groups.length,
                          itemBuilder: (ctx, gi) {
                            final dateKey =
                                groups.keys.elementAt(gi);
                            final txs = groups[dateKey]!;
                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 16, bottom: 8),
                                  child: Text(
                                    dateKey,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      for (int i = 0;
                                          i < txs.length;
                                          i++) ...[
                                        if (i > 0)
                                          Divider(
                                              height: 1,
                                              color: isDark
                                                  ? AppColors.border
                                                  : AppColors.lightBorder),
                                        _TxTile(
                                          tx: txs[i],
                                          textSecondary: textSecondary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransaction(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label:
            const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx, required this.textSecondary});
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (tx.isIncome ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tx.isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: tx.isIncome ? AppColors.success : AppColors.error,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${tx.category} · ${tx.accountName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '−'}EGP ${fmt.format(tx.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tx.isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
