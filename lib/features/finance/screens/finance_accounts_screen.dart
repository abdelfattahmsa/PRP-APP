import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/money/data/models/money_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chart.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/bottom_sheets.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

const _uuid = Uuid();

class FinanceAccountsScreen extends ConsumerWidget {
  const FinanceAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final banksAsync = ref.watch(bankAccountsProvider);
    final txAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(financeSummaryProvider);
    final fmt = NumberFormat('#,##0', 'en_US');

    // 30-day balance trend (running sum from transactions)
    final balanceTrend = txAsync.value == null
        ? List.filled(30, 0.0)
        : () {
            final data = List.filled(30, 0.0);
            final now = DateTime.now();
            double running = summary.totalCurrent + summary.totalSavings;
            for (var i = 29; i >= 0; i--) {
              data[i] = running;
              final dayTx = txAsync.value!.where((t) {
                final diff = now.difference(t.date).inDays;
                return diff == i;
              });
              for (final tx in dayTx) {
                running -= tx.isIncome ? tx.amount : -tx.amount;
              }
            }
            return data;
          }();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            ScreenHeader(
              title: 'Accounts',
              subtitle: 'Your cash and bank accounts',
              action: IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _showBankAccountSheet(context, ref),
              ),
            ),
            const Gap(24),

            // ── KPI Grid ──────────────────────────────────────────
            BentoGrid(
              children: [
                BentoCell(
                  span: 2,
                  child: KpiCard(
                    label: 'Net Cash',
                    value: 'EGP ${fmt.format(summary.totalCurrent + summary.totalSavings)}',
                    icon: Icons.account_balance_rounded,
                    iconColor: AppColors.success,
                    subtitle:
                        'Savings: ${fmt.format(summary.totalSavings)} · Current: ${fmt.format(summary.totalCurrent)}',
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'CC Debt',
                    value: 'EGP ${fmt.format(summary.totalCC)}',
                    icon: Icons.credit_card_rounded,
                    iconColor: AppColors.error,
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Accounts',
                    value: '${banksAsync.value?.length ?? 0}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.info,
                  ),
                ),
              ],
            ),
            const Gap(20),

            // ── Balance Trend ─────────────────────────────────────
            ChartCard(
              title: '30-Day Balance Trend',
              height: 140,
              child: txAsync.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : AppLineChart(
                      data: balanceTrend,
                      color: AppColors.success,
                      showGradient: true,
                    ),
            ),
            const Gap(20),

            // ── Account List ──────────────────────────────────────
            BentoSectionHeader('Accounts'),
            const Gap(12),
            banksAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load accounts'),
              data: (banks) {
                if (banks.isEmpty) {
                  return EmptyState(
                    message: 'No accounts added yet',
                    icon: Icons.account_balance_outlined,
                    compact: true,
                    action: TextButton(
                      onPressed: () => showAddTransaction(context),
                      child: const Text('Add a transaction'),
                    ),
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
                        _AccountDetailTile(
                          bank: banks[i],
                          textSecondary: textSecondary,
                          onTap: () => _showBankAccountSheet(
                              context, ref, existing: banks[i]),
                          onDelete: () => ref
                              .read(bankAccountsProvider.notifier)
                              .delete(banks[i].id),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Gap(20),

            // ── Per-account transaction breakdown ─────────────────
            if (txAsync.value != null && banksAsync.value != null)
              ...(banksAsync.value ?? []).map((bank) {
                final bankTxs = txAsync.value!
                    .where((t) => t.accountName == bank.name)
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                if (bankTxs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BentoSectionHeader('${bank.name} — Recent'),
                    const Gap(12),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < bankTxs.take(3).length;
                              i++) ...[
                            if (i > 0)
                              Divider(
                                  height: 1,
                                  color: isDark
                                      ? AppColors.border
                                      : AppColors.lightBorder),
                            _MiniTxTile(
                                tx: bankTxs[i],
                                textSecondary: textSecondary),
                          ],
                        ],
                      ),
                    ),
                    const Gap(20),
                  ],
                );
              }),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_account',
            onPressed: () => _showBankAccountSheet(context, ref),
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.account_balance_rounded, size: 18),
            label: const Text('Add Account'),
          ),
          const Gap(10),
          FloatingActionButton.extended(
            heroTag: 'add_tx',
            onPressed: () => showAddTransaction(context),
            backgroundColor: accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Transaction'),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailTile extends StatelessWidget {
  const _AccountDetailTile({
    required this.bank,
    required this.textSecondary,
    this.onTap,
    this.onDelete,
  });
  final BankAccount bank;
  final Color textSecondary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final total = bank.currentBalance + bank.savingsBalance - bank.creditCardBalance;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.base, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Text(
                    bank.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    onPressed: onDelete,
                    tooltip: 'Delete account',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const Gap(8),
                Text(
                  'EGP ${fmt.format(total)}',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: total >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            // Balance breakdown
            const Gap(10),
            Row(
              children: [
                const Gap(52),
                _BalancePill(
                  label: 'Current',
                  value: 'EGP ${fmt.format(bank.currentBalance)}',
                  color: AppColors.info,
                ),
                const Gap(8),
                _BalancePill(
                  label: 'Savings',
                  value: 'EGP ${fmt.format(bank.savingsBalance)}',
                  color: AppColors.success,
                ),
                if (bank.hasCard) ...[
                  const Gap(8),
                  _BalancePill(
                    label: 'CC',
                    value: 'EGP ${fmt.format(bank.creditCardBalance)}',
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
            if (bank.hasCard) ...[
              const Gap(8),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: bank.creditCardLimit > 0
                                  ? (bank.creditCardBalance / bank.creditCardLimit).clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 4,
                              backgroundColor:
                                  AppColors.error.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.error),
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'EGP ${fmt.format(bank.creditCardBalance)} / ${fmt.format(bank.creditCardLimit)}',
                          style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                              fontFamily: 'IBMPlexMono'),
                        ),
                      ],
                    ),
                    if (bank.minimumPayment > 0) ...[
                      const Gap(4),
                      Text(
                        'Min. payment: EGP ${fmt.format(bank.minimumPayment)}  ·  Remaining limit: EGP ${fmt.format(bank.remainingCreditLimit)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                            fontFamily: 'IBMPlexMono'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Bank Account Add / Edit ───────────────────────────────────────

Future<void> _showBankAccountSheet(BuildContext context, WidgetRef ref,
    {BankAccount? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _BankAccountSheet(existing: existing),
    ),
  );
}

class _BankAccountSheet extends ConsumerStatefulWidget {
  const _BankAccountSheet({this.existing});
  final BankAccount? existing;

  @override
  ConsumerState<_BankAccountSheet> createState() => _BankAccountSheetState();
}

class _BankAccountSheetState extends ConsumerState<_BankAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _ccBalanceCtrl = TextEditingController();
  final _ccLimitCtrl = TextEditingController();
  bool _hasCard = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final b = widget.existing!;
      _nameCtrl.text = b.name;
      _currentCtrl.text = b.currentBalance > 0 ? b.currentBalance.toString() : '';
      _savingsCtrl.text = b.savingsBalance > 0 ? b.savingsBalance.toString() : '';
      _hasCard = b.hasCard;
      if (b.hasCard) {
        _ccBalanceCtrl.text = b.creditCardBalance > 0 ? b.creditCardBalance.toString() : '';
        _ccLimitCtrl.text = b.creditCardLimit > 0 ? b.creditCardLimit.toString() : '';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentCtrl.dispose();
    _savingsCtrl.dispose();
    _ccBalanceCtrl.dispose();
    _ccLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final acc = BankAccount(
        id: widget.existing?.id ?? _uuid.v4(),
        name: _nameCtrl.text.trim(),
        currentBalance: double.tryParse(_currentCtrl.text) ?? 0,
        savingsBalance: double.tryParse(_savingsCtrl.text) ?? 0,
        creditCardBalance: _hasCard ? (double.tryParse(_ccBalanceCtrl.text) ?? 0) : 0,
        creditCardLimit: _hasCard ? (double.tryParse(_ccLimitCtrl.text) ?? 0) : 0,
        minimumPayment: 0,
        order: widget.existing?.order ?? 0,
      );
      await ref.read(bankAccountsProvider.notifier).upsert(acc);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Text(
                widget.existing == null ? 'Add Account' : 'Edit Account',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Gap(20),

              // Bank name autocomplete
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _nameCtrl.text),
                optionsBuilder: (v) => v.text.isEmpty
                    ? const Iterable.empty()
                    : AppConstants.egyptBanks.where(
                        (b) => b.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (s) => _nameCtrl.text = s,
                fieldViewBuilder: (ctx, ctrl, fn, _) {
                  if (_nameCtrl.text.isNotEmpty && ctrl.text.isEmpty) {
                    ctrl.text = _nameCtrl.text;
                  }
                  return TextField(
                    controller: ctrl,
                    focusNode: fn,
                    onChanged: (v) => _nameCtrl.text = v,
                    decoration: InputDecoration(
                      labelText: 'Bank / Account name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  );
                },
              ),
              const Gap(12),

              Row(children: [
                Expanded(
                  child: _NumField(
                      ctrl: _currentCtrl, label: 'Current balance (EGP)'),
                ),
                const Gap(10),
                Expanded(
                  child: _NumField(
                      ctrl: _savingsCtrl, label: 'Savings balance (EGP)'),
                ),
              ]),
              const Gap(12),

              SwitchListTile(
                value: _hasCard,
                onChanged: (v) => setState(() => _hasCard = v),
                title: const Text('Has credit card'),
                contentPadding: EdgeInsets.zero,
              ),

              if (_hasCard) ...[
                const Gap(4),
                Row(children: [
                  Expanded(
                    child: _NumField(
                        ctrl: _ccBalanceCtrl, label: 'CC balance used (EGP)'),
                  ),
                  const Gap(10),
                  Expanded(
                    child:
                        _NumField(ctrl: _ccLimitCtrl, label: 'CC limit (EGP)'),
                  ),
                ]),
              ],

              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.existing == null ? 'Add Account' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────

class _MiniTxTile extends StatelessWidget {
  const _MiniTxTile({required this.tx, required this.textSecondary});
  final dynamic tx;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final isIncome = tx.isIncome as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 8),
      child: Row(
        children: [
          Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 14,
            color: isIncome ? AppColors.success : AppColors.error,
          ),
          const Gap(10),
          Expanded(
            child: Text(
              tx.description as String,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${isIncome ? '+' : '−'}${fmt.format(tx.amount)}',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
