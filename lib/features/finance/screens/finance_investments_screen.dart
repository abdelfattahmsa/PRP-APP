import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/money/data/models/money_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader, SectionHeader;

const _uuid = Uuid();

class FinanceInvestmentsScreen extends ConsumerWidget {
  const FinanceInvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final invAsync = ref.watch(investmentsProvider);

    return Scaffold(
      body: SafeArea(
        child: invAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (investments) {
            final total = investments.fold(0.0, (s, i) => s + i.amount);
            final fmt = NumberFormat('#,##0.##', 'en_US');

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                ScreenHeader(
                  title: 'Investments',
                  subtitle: 'Portfolio holdings and performance',
                  action: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () =>
                        _showAddInvestmentSheet(context, ref),
                  ),
                ),
                const Gap(24),

                // Summary card
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Portfolio Value',
                            style: TextStyle(
                                color: textSecondary, fontSize: 13)),
                        const Gap(4),
                        Text(
                          '${fmt.format(total)} EGP',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${investments.length} holding${investments.length == 1 ? '' : 's'}',
                          style:
                              TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),

                SectionHeader('Holdings'),
                const Gap(12),

                if (investments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.show_chart_rounded,
                              size: 48, color: textSecondary),
                          const Gap(12),
                          Text('No investments yet',
                              style: TextStyle(color: textSecondary)),
                          const Gap(8),
                          TextButton.icon(
                            onPressed: () =>
                                _showAddInvestmentSheet(context, ref),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add holding'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...investments.map((inv) =>
                      _InvestmentTile(inv: inv, total: total)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InvestmentTile extends ConsumerWidget {
  const _InvestmentTile({required this.inv, required this.total});
  final Investment inv;
  final double total;

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('gold') || t.contains('silver')) return Icons.diamond_rounded;
    if (t.contains('bitcoin') || t.contains('crypto')) return Icons.currency_bitcoin_rounded;
    if (t.contains('stock') || t.contains('share') || t.contains('equity')) return Icons.bar_chart_rounded;
    if (t.contains('bond') || t.contains('bill') || t.contains('treasury')) return Icons.shield_rounded;
    if (t.contains('real estate') || t.contains('property')) return Icons.home_rounded;
    if (t.contains('mutual') || t.contains('fund') || t.contains('etf')) return Icons.pie_chart_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  Color _colorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('gold')) return AppColors.gold;
    if (t.contains('silver')) return AppColors.textSecondary;
    if (t.contains('crypto') || t.contains('bitcoin')) return AppColors.warning;
    if (t.contains('stock') || t.contains('share') || t.contains('equity')) return AppColors.pmp;
    if (t.contains('bond') || t.contains('bill')) return AppColors.cfi;
    if (t.contains('real estate')) return AppColors.success;
    return AppColors.pmp;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final pct = total > 0 ? (inv.amount / total * 100) : 0.0;

    return Dismissible(
      key: ValueKey(inv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete holding?'),
            content: Text('Remove "${inv.type}" from your portfolio?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(investmentsProvider.notifier).delete(inv.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
        onTap: () => _showEditInvestmentSheet(context, ref, inv),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _colorFor(inv.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(inv.type),
                    color: _colorFor(inv.type), size: 22),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.type,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const Gap(2),
                    Text(
                      inv.notes?.isNotEmpty == true ? inv.notes! : inv.unit,
                      style: TextStyle(
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fmt.format(inv.amount)} ${inv.unit}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const Gap(2),
                  Text(
                    '${pct.toStringAsFixed(1)}% of portfolio',
                    style: TextStyle(
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Add / Edit sheet ──────────────────────────────────────────────

Future<void> _showAddInvestmentSheet(BuildContext context, WidgetRef ref) =>
    _showInvestmentSheet(context, ref, null);

Future<void> _showEditInvestmentSheet(
        BuildContext context, WidgetRef ref, Investment inv) =>
    _showInvestmentSheet(context, ref, inv);

Future<void> _showInvestmentSheet(
    BuildContext context, WidgetRef ref, Investment? existing) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _InvestmentSheet(existing: existing),
    ),
  );
}

const _investmentTypes = [
  'Stocks',
  'ETF / Mutual Fund',
  'Gold',
  'Silver',
  'Crypto / Bitcoin',
  'Real Estate',
  'Bonds / T-Bills',
  'Cash Equivalent',
  'Other',
];

const _units = ['EGP', 'USD', 'EUR', 'GBP', 'g', 'oz', 'BTC', 'shares'];

class _InvestmentSheet extends ConsumerStatefulWidget {
  const _InvestmentSheet({this.existing});
  final Investment? existing;

  @override
  ConsumerState<_InvestmentSheet> createState() => _InvestmentSheetState();
}

class _InvestmentSheetState extends ConsumerState<_InvestmentSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = _investmentTypes.first;
  String _unit = _units.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final inv = widget.existing!;
      _type = _investmentTypes.contains(inv.type) ? inv.type : _investmentTypes.first;
      _unit = _units.contains(inv.unit) ? inv.unit : _units.first;
      _amountCtrl.text = inv.amount.toString();
      _notesCtrl.text = inv.notes ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final inv = Investment(
      id: widget.existing?.id ?? _uuid.v4(),
      type: _type,
      amount: amount,
      unit: _unit,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      purchaseDate: widget.existing?.purchaseDate ?? DateTime.now(),
    );
    await ref.read(investmentsProvider.notifier).add(inv);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              widget.existing == null ? 'Add Holding' : 'Edit Holding',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Gap(20),

            // Type dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Investment Type',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _investmentTypes
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: _units
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const Gap(12),

            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. 12 shares of VOO, 0.5 oz gold bar',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
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
                    : Text(widget.existing == null ? 'Add Holding' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
