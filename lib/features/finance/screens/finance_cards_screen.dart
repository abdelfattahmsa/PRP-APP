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
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

const _uuid = Uuid();

class FinanceCardsScreen extends ConsumerWidget {
  const FinanceCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardsAsync = ref.watch(creditCardsProvider);
    final plansAsync = ref.watch(installmentPlansProvider);
    final summary = ref.watch(financeSummaryProvider);
    final fmt = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            ScreenHeader(
              title: 'Cards & Installments',
              subtitle: 'Credit cards and payment plans',
              action: PopupMenuButton<String>(
                icon: const Icon(Icons.add_rounded),
                onSelected: (v) {
                  if (v == 'card') _showCreditCardSheet(context, ref);
                  if (v == 'plan') _showInstallmentSheet(context, ref);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'card', child: Text('Add Credit Card')),
                  PopupMenuItem(
                      value: 'plan', child: Text('Add Installment Plan')),
                ],
              ),
            ),
            const Gap(20),

            // ── Monthly Obligations ──────────────────────────────
            if (summary.totalMonthlyObligation > 0) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_month_outlined,
                          size: 16, color: AppColors.warning),
                      const Gap(8),
                      Text(
                        'This Month\'s Obligations',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ]),
                    const Gap(16),
                    Row(children: [
                      _ObligationChip(
                        label: 'CC Min Payments',
                        value: 'EGP ${fmt.format(summary.totalCCFromCards > 0 ? (cardsAsync.value ?? []).fold(0.0, (s, c) => s + c.minPaymentAmount) : 0)}',
                        color: AppColors.error,
                      ),
                      const Gap(10),
                      _ObligationChip(
                        label: 'Installments',
                        value: 'EGP ${fmt.format(summary.totalInstallments)}',
                        color: AppColors.warning,
                      ),
                    ]),
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL DUE THIS MONTH',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 9,
                            letterSpacing: 1,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          'EGP ${fmt.format(summary.totalMonthlyObligation)}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(20),
            ],

            // ── Credit Cards ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BentoSectionHeader('Credit Cards'),
                TextButton.icon(
                  onPressed: () => _showCreditCardSheet(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Gap(8),
            cardsAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load credit cards'),
              data: (cards) {
                if (cards.isEmpty) {
                  return EmptyState(
                    message: 'No credit cards added',
                    icon: Icons.credit_card_outlined,
                    compact: true,
                    action: TextButton(
                      onPressed: () => _showCreditCardSheet(context, ref),
                      child: const Text('Add credit card'),
                    ),
                  );
                }
                return Column(
                  children: cards
                      .map((c) => _CreditCardTile(
                            card: c,
                            textSecondary: textSecondary,
                            onEdit: () =>
                                _showCreditCardSheet(context, ref, existing: c),
                            onDelete: () => ref
                                .read(creditCardsProvider.notifier)
                                .delete(c.id),
                          ))
                      .toList(),
                );
              },
            ),
            const Gap(24),

            // ── Installment Plans ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BentoSectionHeader('Installment Plans'),
                TextButton.icon(
                  onPressed: () => _showInstallmentSheet(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Gap(8),
            plansAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load installment plans'),
              data: (plans) {
                final active = plans.where((p) => !p.isCompleted).toList();
                final done = plans.where((p) => p.isCompleted).toList();
                if (plans.isEmpty) {
                  return EmptyState(
                    message: 'No installment plans',
                    icon: Icons.payments_outlined,
                    compact: true,
                    action: TextButton(
                      onPressed: () => _showInstallmentSheet(context, ref),
                      child: const Text('Add plan'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...active.map((p) => _InstallmentTile(
                          plan: p,
                          textSecondary: textSecondary,
                          onEdit: () =>
                              _showInstallmentSheet(context, ref, existing: p),
                          onDelete: () => ref
                              .read(installmentPlansProvider.notifier)
                              .delete(p.id),
                          onMarkPaid: () =>
                              _markNextInstallment(context, ref, p),
                        )),
                    if (done.isNotEmpty) ...[
                      const Gap(12),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: textSecondary,
                        ),
                      ),
                      const Gap(8),
                      ...done.map((p) => _InstallmentTile(
                            plan: p,
                            textSecondary: textSecondary,
                            onEdit: () => _showInstallmentSheet(context, ref,
                                existing: p),
                            onDelete: () => ref
                                .read(installmentPlansProvider.notifier)
                                .delete(p.id),
                          )),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_card',
            onPressed: () => _showCreditCardSheet(context, ref),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.credit_card_rounded, size: 18),
            label: const Text('Add Card'),
          ),
          const Gap(10),
          FloatingActionButton.extended(
            heroTag: 'add_plan',
            onPressed: () => _showInstallmentSheet(context, ref),
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.payments_rounded, size: 18),
            label: const Text('Add Plan'),
          ),
        ],
      ),
    );
  }
}

// ── Mark next installment as paid ────────────────────────────────
Future<void> _markNextInstallment(
    BuildContext context, WidgetRef ref, InstallmentPlan plan) async {
  if (plan.isCompleted) return;
  final newPaid = plan.paidMonths + 1;
  await ref.read(installmentPlansProvider.notifier).markPaid(plan.id, newPaid);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✓ Marked payment ${newPaid}/${plan.totalMonths} as paid'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// ── Obligation Chip ───────────────────────────────────────────────
class _ObligationChip extends StatelessWidget {
  const _ObligationChip(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 9,
                    color: color,
                    letterSpacing: 0.5)),
            const Gap(4),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Credit Card Tile ──────────────────────────────────────────────
class _CreditCardTile extends StatelessWidget {
  const _CreditCardTile({
    required this.card,
    required this.textSecondary,
    this.onEdit,
    this.onDelete,
  });
  final CreditCard card;
  final Color textSecondary;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final utilColor = card.utilizationPct > 0.8
        ? AppColors.error
        : card.utilizationPct > 0.5
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: card.isOverLimit
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withValues(alpha: 0.12),
                  AppColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      size: 20, color: AppColors.error),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      if (card.bank.isNotEmpty)
                        Text(
                          card.bank,
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: textSecondary),
                        ),
                    ],
                  ),
                ),
                // Due date badge
                if (card.balance > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due in ${card.daysUntilDue}d',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: card.daysUntilDue <= 5
                              ? AppColors.error
                              : textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(card.nextDueDate),
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 9,
                            color: textSecondary),
                      ),
                    ],
                  ),
                  const Gap(8),
                ],
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 16, color: textSecondary),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Gap(4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                // Balance / Limit row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CardStat(
                        label: 'Balance',
                        value:
                            '${card.currency} ${fmt.format(card.balance)}',
                        color: AppColors.error),
                    _CardStat(
                        label: 'Remaining',
                        value:
                            '${card.currency} ${fmt.format(card.remainingLimit)}',
                        color: card.isOverLimit
                            ? AppColors.error
                            : AppColors.success),
                    _CardStat(
                        label: 'Min Payment',
                        value:
                            '${card.currency} ${fmt.format(card.minPaymentAmount)}',
                        color: AppColors.warning),
                    if (card.apr > 0)
                      _CardStat(
                          label: 'APR',
                          value: '${(card.apr * 100).toStringAsFixed(1)}%',
                          color: textSecondary),
                  ],
                ),
                const Gap(10),
                // Utilization bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: card.utilizationPct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(utilColor),
                  ),
                ),
                const Gap(6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(card.utilizationPct * 100).toStringAsFixed(0)}% utilized',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          color: utilColor),
                    ),
                    Text(
                      'Limit: ${card.currency} ${fmt.format(card.limit)}',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 8,
                  color: color.withValues(alpha: 0.7))),
          const Gap(2),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      );
}

// ── Installment Plan Tile ─────────────────────────────────────────
class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({
    required this.plan,
    required this.textSecondary,
    this.onEdit,
    this.onDelete,
    this.onMarkPaid,
  });
  final InstallmentPlan plan;
  final Color textSecondary;
  final VoidCallback? onEdit, onDelete, onMarkPaid;

  static const _providerColors = {
    'Valu': Color(0xFF7C3AED),
    'Tru (TruValue)': Color(0xFF0891B2),
    'Contact Finance': Color(0xFFD97706),
    'Sympl': Color(0xFF059669),
    'Aman': Color(0xFFDC2626),
    'Bank Takseet': AppColors.info,
    'Other': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final provColor =
        _providerColors[plan.provider] ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: plan.isCompleted
            ? AppColors.card.withValues(alpha: 0.5)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: plan.isCompleted
                ? AppColors.border.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: provColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: provColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    plan.provider,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: provColor),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    plan.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: plan.isCompleted
                          ? textSecondary
                          : null,
                      decoration: plan.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (!plan.isCompleted && onMarkPaid != null)
                  TextButton(
                    onPressed: onMarkPaid,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Mark paid',
                        style: TextStyle(fontSize: 11)),
                  ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 14, color: textSecondary),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Gap(4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: AppColors.error),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Gap(10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: plan.progressPct,
                minHeight: 5,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                    plan.isCompleted ? AppColors.success : provColor),
              ),
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${plan.paidMonths}/${plan.totalMonths} months  ·  '
                  '${plan.currency} ${fmt.format(plan.monthlyPayment)}/mo',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: textSecondary),
                ),
                Text(
                  plan.isCompleted
                      ? '✓ Done'
                      : '${plan.currency} ${fmt.format(plan.remainingAmount)} left',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: plan.isCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CREDIT CARD SHEET
// ══════════════════════════════════════════════════════════════

Future<void> _showCreditCardSheet(BuildContext context, WidgetRef ref,
    {CreditCard? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _CreditCardSheet(existing: existing),
    ),
  );
}

class _CreditCardSheet extends ConsumerStatefulWidget {
  const _CreditCardSheet({this.existing});
  final CreditCard? existing;

  @override
  ConsumerState<_CreditCardSheet> createState() => _CreditCardSheetState();
}

class _CreditCardSheetState extends ConsumerState<_CreditCardSheet> {
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _aprCtrl = TextEditingController();
  double _minPaymentPct = 0.05;
  int _statementDay = 25;
  int _dueDay = 5;
  String _currency = 'EGP';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final c = widget.existing!;
      _nameCtrl.text = c.name;
      _bankCtrl.text = c.bank;
      _balanceCtrl.text = c.balance > 0 ? c.balance.toString() : '';
      _limitCtrl.text = c.limit > 0 ? c.limit.toString() : '';
      _aprCtrl.text = c.apr > 0 ? (c.apr * 100).toStringAsFixed(1) : '';
      _minPaymentPct = c.minPaymentPct;
      _statementDay = c.statementDay;
      _dueDay = c.dueDay;
      _currency = c.currency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _balanceCtrl.dispose();
    _limitCtrl.dispose();
    _aprCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final card = CreditCard(
        id: widget.existing?.id ?? _uuid.v4(),
        name: _nameCtrl.text.trim(),
        bank: _bankCtrl.text.trim(),
        balance: double.tryParse(_balanceCtrl.text) ?? 0,
        limit: double.tryParse(_limitCtrl.text) ?? 0,
        minPaymentPct: _minPaymentPct,
        apr: (double.tryParse(_aprCtrl.text) ?? 0) / 100,
        statementDay: _statementDay,
        dueDay: _dueDay,
        currency: _currency,
        order: widget.existing?.order ?? 0,
      );
      await ref.read(creditCardsProvider.notifier).upsert(card);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark ? AppColors.border : Colors.grey.shade200;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Text(
                widget.existing == null
                    ? 'Add Credit Card'
                    : 'Edit Credit Card',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Gap(20),

              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card nickname *',
                  hintText: 'e.g. CIB Visa Platinum',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(12),

              // Bank autocomplete
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _bankCtrl.text),
                optionsBuilder: (v) => v.text.isEmpty
                    ? const Iterable.empty()
                    : AppConstants.egyptBanks.where((b) =>
                        b.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (s) => _bankCtrl.text = s,
                fieldViewBuilder: (ctx, ctrl, fn, _) {
                  if (_bankCtrl.text.isNotEmpty && ctrl.text.isEmpty) {
                    ctrl.text = _bankCtrl.text;
                  }
                  return TextField(
                    controller: ctrl,
                    focusNode: fn,
                    onChanged: (v) => _bankCtrl.text = v,
                    decoration: InputDecoration(
                      labelText: 'Bank',
                      hintText: 'e.g. CIB',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  );
                },
              ),
              const Gap(12),

              // Balance + Limit
              Row(children: [
                Expanded(child: _NumField(ctrl: _balanceCtrl, label: 'Balance used')),
                const Gap(10),
                Expanded(child: _NumField(ctrl: _limitCtrl, label: 'Credit limit')),
              ]),
              const Gap(12),

              // APR + Currency
              Row(children: [
                Expanded(
                  child: _NumField(
                      ctrl: _aprCtrl, label: 'APR % (annual)', hint: 'e.g. 36'),
                ),
                const Gap(10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: const ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'EGP'),
                  ),
                ),
              ]),
              const Gap(16),

              // Min payment %
              Text(
                'MIN. PAYMENT: ${(_minPaymentPct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary),
              ),
              Slider(
                value: _minPaymentPct,
                min: 0.01,
                max: 0.20,
                divisions: 19,
                label: '${(_minPaymentPct * 100).toStringAsFixed(0)}%',
                activeColor: AppColors.warning,
                onChanged: (v) =>
                    setState(() => _minPaymentPct = v),
              ),
              const Gap(8),

              // Statement day + Due day
              Row(children: [
                Expanded(
                  child: _DayDropdown(
                    label: 'Statement closes day',
                    value: _statementDay,
                    onChanged: (v) => setState(() => _statementDay = v),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _DayDropdown(
                    label: 'Payment due day',
                    value: _dueDay,
                    onChanged: (v) => setState(() => _dueDay = v),
                  ),
                ),
              ]),
              const Gap(24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.existing == null
                              ? 'Add Card'
                              : 'Save Card',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// INSTALLMENT PLAN SHEET
// ══════════════════════════════════════════════════════════════

Future<void> _showInstallmentSheet(BuildContext context, WidgetRef ref,
    {InstallmentPlan? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _InstallmentSheet(existing: existing),
    ),
  );
}

class _InstallmentSheet extends ConsumerStatefulWidget {
  const _InstallmentSheet({this.existing});
  final InstallmentPlan? existing;

  @override
  ConsumerState<_InstallmentSheet> createState() => _InstallmentSheetState();
}

class _InstallmentSheetState extends ConsumerState<_InstallmentSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _provider = kInstallmentProviders.first;
  int _totalMonths = 12;
  int _paidMonths = 0;
  String _currency = 'EGP';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final p = widget.existing!;
      _descCtrl.text = p.description;
      _amountCtrl.text = p.originalAmount > 0
          ? p.originalAmount.toString()
          : '';
      _monthlyCtrl.text = p.monthlyPayment > 0
          ? p.monthlyPayment.toString()
          : '';
      _notesCtrl.text = p.notes ?? '';
      _provider = p.provider;
      _totalMonths = p.totalMonths;
      _paidMonths = p.paidMonths;
      _currency = p.currency;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _monthlyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_descCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final plan = InstallmentPlan(
        id: widget.existing?.id ?? _uuid.v4(),
        description: _descCtrl.text.trim(),
        provider: _provider,
        originalAmount: double.tryParse(_amountCtrl.text) ?? 0,
        monthlyPayment: double.tryParse(_monthlyCtrl.text) ?? 0,
        totalMonths: _totalMonths,
        paidMonths: _paidMonths,
        currency: _currency,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await ref.read(installmentPlansProvider.notifier).upsert(plan);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark ? AppColors.border : Colors.grey.shade200;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Text(
                widget.existing == null
                    ? 'Add Installment Plan'
                    : 'Edit Installment Plan',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Gap(20),

              // Description
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'e.g. iPhone 16 Pro',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(12),

              // Provider
              DropdownButtonFormField<String>(
                value: kInstallmentProviders.contains(_provider)
                    ? _provider
                    : kInstallmentProviders.last,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: kInstallmentProviders
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _provider = v ?? _provider),
              ),
              const Gap(12),

              // Amount + Monthly
              Row(children: [
                Expanded(
                    child: _NumField(
                        ctrl: _amountCtrl,
                        label: 'Total amount',
                        hint: '10000')),
                const Gap(10),
                Expanded(
                    child: _NumField(
                        ctrl: _monthlyCtrl,
                        label: 'Monthly payment',
                        hint: '833')),
              ]),
              const Gap(12),

              // Total months
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL MONTHS: $_totalMonths',
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary),
                      ),
                      Slider(
                        value: _totalMonths.toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59,
                        label: '$_totalMonths mo',
                        activeColor: AppColors.warning,
                        onChanged: (v) =>
                            setState(() => _totalMonths = v.round()),
                      ),
                    ],
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAID MONTHS: $_paidMonths',
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary),
                      ),
                      Slider(
                        value: _paidMonths.toDouble(),
                        min: 0,
                        max: _totalMonths.toDouble(),
                        divisions:
                            _totalMonths > 1 ? _totalMonths - 1 : 1,
                        label: '$_paidMonths mo',
                        activeColor: AppColors.success,
                        onChanged: (v) =>
                            setState(() => _paidMonths = v.round()),
                      ),
                    ],
                  ),
                ),
              ]),
              const Gap(8),

              // Currency
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const ['EGP', 'USD', 'EUR', 'GBP']
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _currency = v ?? 'EGP'),
              ),
              const Gap(12),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.existing == null
                              ? 'Add Plan'
                              : 'Save Plan',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared form helpers ────────────────────────────────────────────

class _NumField extends StatelessWidget {
  const _NumField(
      {required this.ctrl, required this.label, this.hint = ''});
  final TextEditingController ctrl;
  final String label, hint;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

class _DayDropdown extends StatelessWidget {
  const _DayDropdown(
      {required this.label,
      required this.value,
      required this.onChanged});
  final String label;
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: List.generate(
        28,
        (i) => DropdownMenuItem(
          value: i + 1,
          child: Text('${i + 1}'),
        ),
      ),
      onChanged: (v) => onChanged(v ?? value),
    );
  }
}
