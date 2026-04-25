import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/money/data/models/money_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';

import '../../../shared/widgets/placeholders.dart' show ScreenHeader, SectionHeader;

const _uuid = Uuid();

class FinanceLiabilitiesScreen extends ConsumerWidget {
  const FinanceLiabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      body: SafeArea(
        child: debtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (debts) {
            final activeDebts = debts.where((d) => !d.isPaid).toList();
            final total =
                activeDebts.fold(0.0, (s, d) => s + d.amount);
            final fmt = NumberFormat('#,##0.##', 'en_US');

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                ScreenHeader(
                  title: 'Liabilities',
                  subtitle: 'Debts and obligations',
                  action: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showDebtSheet(context, ref),
                  ),
                ),
                const Gap(24),

                // Summary
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Outstanding',
                            style: TextStyle(
                                color: textSecondary, fontSize: 13)),
                        const Gap(4),
                        Text(
                          'EGP ${fmt.format(total)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${activeDebts.length} active debt${activeDebts.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),

                SectionHeader('Debts'),
                const Gap(12),

                if (activeDebts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 48, color: AppColors.success),
                          const Gap(12),
                          Text('No outstanding debts!',
                              style: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600)),
                          const Gap(8),
                          TextButton.icon(
                            onPressed: () => _showDebtSheet(context, ref),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Record a debt'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...activeDebts.map((debt) => _DebtTile(debt: debt)),

                if (debts.any((d) => d.isPaid)) ...[
                  const Gap(24),
                  SectionHeader('Paid Off'),
                  const Gap(12),
                  ...debts
                      .where((d) => d.isPaid)
                      .map((debt) => _DebtTile(debt: debt, dim: true)),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDebtSheet(context, ref),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Debt'),
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  const _DebtTile({required this.debt, this.dim = false});
  final ExternalDebt debt;
  final bool dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final fmt = NumberFormat('#,##0.##', 'en_US');

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete debt?'),
          content: Text('Remove "${debt.source}"?'),
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
      ),
      onDismissed: (_) =>
          ref.read(debtsProvider.notifier).delete(debt.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          onTap: () => _showDebtSheet(context, ref, existing: debt),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (debt.isPaid ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    debt.isPaid
                        ? Icons.check_circle_rounded
                        : Icons.money_off_rounded,
                    color:
                        debt.isPaid ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.source,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: dim ? textSecondary : null)),
                      if (debt.notes?.isNotEmpty == true) ...[
                        const Gap(2),
                        Text(debt.notes!,
                            style: TextStyle(
                                color: textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (debt.dueDate != null) ...[
                        const Gap(2),
                        Text(
                          'Due ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}',
                          style: TextStyle(
                              color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EGP ${fmt.format(debt.amount)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: debt.isPaid ? textSecondary : AppColors.error),
                    ),
                    if (debt.isPaid)
                      Text('Paid',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
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

// ── Debt Add / Edit sheet ──────────────────────────────────────────

Future<void> _showDebtSheet(BuildContext context, WidgetRef ref,
    {ExternalDebt? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _DebtSheet(existing: existing),
    ),
  );
}

class _DebtSheet extends ConsumerStatefulWidget {
  const _DebtSheet({this.existing});
  final ExternalDebt? existing;

  @override
  ConsumerState<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends ConsumerState<_DebtSheet> {
  final _sourceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isPaid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!;
      _sourceCtrl.text = d.source;
      _amountCtrl.text = d.amount.toString();
      _notesCtrl.text = d.notes ?? '';
      _dueDate = d.dueDate;
      _isPaid = d.isPaid;
    }
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_sourceCtrl.text.trim().isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;
    setState(() => _saving = true);
    final debt = ExternalDebt(
      id: widget.existing?.id ?? _uuid.v4(),
      source: _sourceCtrl.text.trim(),
      amount: amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      dueDate: _dueDate,
      isPaid: _isPaid,
    );
    await ref.read(debtsProvider.notifier).upsert(debt);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              widget.existing == null ? 'Add Debt' : 'Edit Debt',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Gap(20),

            TextField(
              controller: _sourceCtrl,
              decoration: InputDecoration(
                labelText: 'Source / Creditor',
                hintText: 'e.g. Bank Loan, Personal, Mortgage',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const Gap(12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (EGP)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const Gap(12),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const Gap(12),

            // Due date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isDark
                          ? AppColors.border
                          : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Due date (optional)'
                            : 'Due: ${DateFormat('MMM d, yyyy').format(_dueDate!)}',
                        style: TextStyle(
                            color: _dueDate == null ? textSecondary : null),
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.clear_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const Gap(8),

            SwitchListTile(
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v),
              title: const Text('Mark as paid'),
              contentPadding: EdgeInsets.zero,
            ),
            const Gap(16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : Text(
                        widget.existing == null ? 'Add Debt' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
