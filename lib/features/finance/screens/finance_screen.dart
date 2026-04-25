import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_text_field.dart';

const _uuid = Uuid();

final _fmt = NumberFormat('#,##0', 'en');
String egp(double v) => 'EGP ${_fmt.format(v)}';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financeSummaryProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'BANKS'),
              Tab(text: 'DEBTS'),
              Tab(text: 'TRANSACTIONS'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _OverviewTab(summary: summary),
          const _BanksTab(),
          const _DebtsTab(),
          const _TransactionsTab(),
        ]),
      ),
    );
  }
}

// ── OVERVIEW TAB ─────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.summary});
  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final debtProgress = (summary.totalDebt / 200000).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Debt reduction card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1F0D0D), Color(0xFF130D1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total Debt', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                child: const Text('TARGET ≤ 100K · SEP 2026', style: TextStyle(fontSize: 8, color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            ]),
            const Gap(8),
            Text(egp(summary.totalDebt), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.error)),
            const Gap(12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debtProgress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(Color.lerp(AppColors.deen, AppColors.error, debtProgress)!),
              ),
            ),
            const Gap(6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(egp(summary.totalDebt), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('${((1 - debtProgress) * 100).toStringAsFixed(0)}% to target', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const Text('100K', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ]),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
        const Gap(14),
        // Summary grid
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
          children: [
            _SummaryCard(label: 'CC Balance',       value: egp(summary.totalCC),         color: AppColors.error),
            _SummaryCard(label: 'Remaining Limit',  value: egp(summary.remainingLimit),   color: summary.remainingLimit < 0 ? AppColors.error : AppColors.deen),
            _SummaryCard(label: 'Total Savings',    value: egp(summary.totalSavings),     color: AppColors.gold),
            _SummaryCard(label: 'Cash + Current',   value: egp(summary.totalCurrent),     color: AppColors.pmp),
            _SummaryCard(label: 'External Debts',   value: egp(summary.totalExtDebt),     color: AppColors.fasting),
            _SummaryCard(label: "Today's Spend",    value: egp(summary.todaySpend),       color: AppColors.kyberia),
          ],
        ),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const Gap(4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ── BANKS TAB ────────────────────────────────────────────────
class _BanksTab extends ConsumerWidget {
  const _BanksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banksAsync = ref.watch(bankAccountsProvider);
    return banksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text('Unable to load data. Please try again.', style: const TextStyle(color: AppColors.error))),
      data: (banks) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...banks.asMap().entries.map((e) => _BankCard(bank: e.value, index: e.key)),
          const Gap(10),
          // Cash on hand
          _CashCard(),
          const Gap(10),
          // Add bank button
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Bank Account'),
            onPressed: () => ref.read(bankAccountsProvider.notifier).addNew(),
          ),
        ],
      ),
    );
  }
}

class _BankCard extends ConsumerStatefulWidget {
  const _BankCard({required this.bank, required this.index});
  final BankAccount bank;
  final int index;
  @override
  ConsumerState<_BankCard> createState() => _BankCardState();
}

class _BankCardState extends ConsumerState<_BankCard> {
  late TextEditingController _name, _cc, _limit, _sav, _cur;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _name  = TextEditingController(text: widget.bank.name);
    _cc    = TextEditingController(text: widget.bank.creditCardBalance.toStringAsFixed(0));
    _limit = TextEditingController(text: widget.bank.creditCardLimit.toStringAsFixed(0));
    _sav   = TextEditingController(text: widget.bank.savingsBalance.toStringAsFixed(0));
    _cur   = TextEditingController(text: widget.bank.currentBalance.toStringAsFixed(0));
  }

  @override
  void dispose() { _name.dispose(); _cc.dispose(); _limit.dispose(); _sav.dispose(); _cur.dispose(); super.dispose(); }

  void _save() {
    final updated = widget.bank.copyWith(
      name: _name.text,
      creditCardBalance: double.tryParse(_cc.text) ?? 0,
      creditCardLimit:   double.tryParse(_limit.text) ?? 0,
      savingsBalance:    double.tryParse(_sav.text) ?? 0,
      currentBalance:    double.tryParse(_cur.text) ?? 0,
    );
    ref.read(bankAccountsProvider.notifier).upsert(updated);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final rem = widget.bank.remainingCreditLimit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _editing
              ? Expanded(child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: _name.text),
                  optionsBuilder: (v) => AppConstants.egyptBanks.where(
                      (b) => b.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (v) => _name.text = v,
                  fieldViewBuilder: (_, ctrl, focus, onSubmit) => TextField(
                    controller: ctrl,
                    focusNode: focus,
                    onEditingComplete: onSubmit,
                    style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onChanged: (v) => _name.text = v,
                  ),
                ))
              : Expanded(child: Text(widget.bank.name, style: Theme.of(context).textTheme.titleLarge)),
          IconButton(
            icon: Icon(_editing ? Icons.check : Icons.edit_outlined, size: 16, color: _editing ? AppColors.deen : AppColors.textSecondary),
            onPressed: _editing ? _save : () => setState(() => _editing = true),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          if (!_editing) IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            onPressed: () => ref.read(bankAccountsProvider.notifier).delete(widget.bank.id),
            padding: const EdgeInsets.only(left: 8), constraints: const BoxConstraints(),
          ),
        ]),
        const Gap(12),
        _editing
            ? Column(children: [
                Row(children: [
                  Expanded(child: _NumField(ctrl: _cc, label: 'CC Balance')),
                  const Gap(10),
                  Expanded(child: _NumField(ctrl: _limit, label: 'CC Limit')),
                ]),
                const Gap(8),
                Row(children: [
                  Expanded(child: _NumField(ctrl: _sav, label: 'Savings')),
                  const Gap(10),
                  Expanded(child: _NumField(ctrl: _cur, label: 'Current')),
                ]),
              ])
            : Row(children: [
                Expanded(child: _BankStat(label: 'CC Balance', value: egp(widget.bank.creditCardBalance), color: AppColors.error)),
                Expanded(child: _BankStat(label: 'Rem. Limit', value: egp(rem), color: rem < 0 ? AppColors.error : AppColors.deen)),
                Expanded(child: _BankStat(label: 'Savings', value: egp(widget.bank.savingsBalance), color: AppColors.gold)),
                Expanded(child: _BankStat(label: 'Current', value: egp(widget.bank.currentBalance), color: AppColors.pmp)),
              ]),
        if (!_editing && widget.bank.creditCardLimit > 0) ...[
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (widget.bank.creditCardBalance / widget.bank.creditCardLimit).clamp(0, 1),
              minHeight: 4, backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(rem < 0 ? AppColors.error : AppColors.fasting),
            ),
          ),
          const Gap(4),
          Text('Limit: ${egp(widget.bank.creditCardLimit)}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ]),
    ).animate(delay: (widget.index * 60).ms).fadeIn(duration: 250.ms).slideY(begin: 0.05);
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
    const Gap(3),
    TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8))),
  ]);
}

class _BankStat extends StatelessWidget {
  const _BankStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary)),
    const Gap(3),
    Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  ]);
}

class _CashCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CashCard> createState() => _CashCardState();
}

class _CashCardState extends ConsumerState<_CashCard> {
  final _ctrl = TextEditingController();
  bool _editing = false;
  bool _initialized = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _save() {
    final amount = double.tryParse(_ctrl.text) ?? 0;
    ref.read(cashOnHandProvider.notifier).set(amount);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cashAsync = ref.watch(cashOnHandProvider);
    final cash = cashAsync.value ?? 0;
    // Initialize controller with provider value once
    if (!_initialized && !_editing) {
      _ctrl.text = cash.toStringAsFixed(0);
      if (cashAsync.hasValue) _initialized = true;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.payments_outlined, size: 18, color: AppColors.gold),
        const Gap(10),
        const Expanded(child: Text('Cash on Hand', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 14, fontWeight: FontWeight.w700))),
        _editing
            ? SizedBox(width: 100, child: TextField(controller: _ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.right, autofocus: true, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)), onSubmitted: (_) => _save()))
            : Text('EGP ${_fmt.format(cash)}', style: const TextStyle(fontSize: 13, color: AppColors.gold, fontWeight: FontWeight.w600)),
        const Gap(8),
        IconButton(
          icon: Icon(_editing ? Icons.check : Icons.edit_outlined, size: 16, color: AppColors.gold),
          onPressed: _editing ? _save : () => setState(() => _editing = true),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ── DEBTS TAB ────────────────────────────────────────────────
class _DebtsTab extends ConsumerStatefulWidget {
  const _DebtsTab();
  @override
  ConsumerState<_DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends ConsumerState<_DebtsTab> {
  bool _adding = false;
  final _src = TextEditingController();
  final _amt = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() { _src.dispose(); _amt.dispose(); _note.dispose(); super.dispose(); }

  void _add() {
    if (_src.text.isEmpty || _amt.text.isEmpty) return;
    ref.read(debtsProvider.notifier).add(ExternalDebt(id: _uuid.v4(), source: _src.text.trim(), amount: double.tryParse(_amt.text) ?? 0, notes: _note.text.trim().isEmpty ? null : _note.text.trim()));
    _src.clear(); _amt.clear(); _note.clear();
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    return debtsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text('Something went wrong. Please try again.', style: const TextStyle(color: AppColors.error))),
      data: (debts) {
        final total = debts.fold(0.0, (s, d) => s + d.amount);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (debts.isNotEmpty) Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total External Debt', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(egp(total), style: const TextStyle(fontSize: 16, color: AppColors.error, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Gap(10),
            if (_adding) _AddDebtForm(src: _src, amt: _amt, note: _note, onSave: _add, onCancel: () => setState(() { _adding = false; _src.clear(); _amt.clear(); _note.clear(); })),
            if (!_adding) OutlinedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Add Debt'), onPressed: () => setState(() => _adding = true)),
            const Gap(10),
            ...debts.map((d) => _DebtTile(debt: d)),
          ],
        );
      },
    );
  }
}

class _AddDebtForm extends StatelessWidget {
  const _AddDebtForm({required this.src, required this.amt, required this.note, required this.onSave, required this.onCancel});
  final TextEditingController src, amt, note;
  final VoidCallback onSave, onCancel;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Row(children: [
        Expanded(child: AppTextField(controller: src, label: 'Person / Source', hint: 'e.g. Ahmed')),
        const Gap(10),
        Expanded(child: AppTextField(controller: amt, label: 'Amount (EGP)', hint: '5000', keyboardType: TextInputType.number)),
      ]),
      const Gap(10),
      AppTextField(controller: note, label: 'Note (optional)', hint: 'Any details...'),
      const Gap(10),
      Row(children: [
        Expanded(child: ElevatedButton(onPressed: onSave, child: const Text('Save'))),
        const Gap(10),
        Expanded(child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
      ]),
    ]),
  );
}

class _DebtTile extends ConsumerWidget {
  const _DebtTile({required this.debt});
  final ExternalDebt debt;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(debt.source, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        if (debt.notes != null) Text(debt.notes!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
      ])),
      Text(egp(debt.amount), style: const TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.w600)),
      const Gap(8),
      IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), onPressed: () => ref.read(debtsProvider.notifier).delete(debt.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
    ]),
  );
}

// ── TRANSACTIONS TAB ─────────────────────────────────────────
class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab();
  @override
  ConsumerState<_TransactionsTab> createState() => _TxTabState();
}

class _TxTabState extends ConsumerState<_TransactionsTab> {
  String _catFilter = 'All';
  bool _adding = false;
  final _desc = TextEditingController();
  final _amt  = TextEditingController();
  String _cat = 'General';
  String _acct = 'Cash';
  DateTime _date = DateTime.now();

  @override
  void dispose() { _desc.dispose(); _amt.dispose(); super.dispose(); }

  void _add() {
    if (_desc.text.isEmpty || _amt.text.isEmpty) return;
    ref.read(transactionsProvider.notifier).add(Transaction(
      id: _uuid.v4(), date: _date, description: _desc.text.trim(),
      amount: double.tryParse(_amt.text) ?? 0,
      category: _cat, accountName: _acct,
    ));
    _desc.clear(); _amt.clear();
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final banks = ref.watch(bankAccountsProvider).value ?? [];
    final accounts = [...banks.map((b) => b.name), 'Cash'];

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text('Something went wrong. Please try again.', style: const TextStyle(color: AppColors.error))),
      data: (txs) {
        final filtered = _catFilter == 'All' ? txs : txs.where((t) => t.category == _catFilter).toList();
        final total = filtered.fold(0.0, (s, t) => s + t.amount);

        return Column(children: [
          if (_adding) _AddTxForm(desc: _desc, amt: _amt, cat: _cat, acct: _acct, date: _date, accounts: accounts,
              onCatChange: (v) => setState(() => _cat = v),
              onAcctChange: (v) => setState(() => _acct = v),
              onDateChange: (v) => setState(() => _date = v),
              onSave: _add,
              onCancel: () => setState(() { _adding = false; _desc.clear(); _amt.clear(); }),
          ),
          // Category filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All', ...AppConstants.txCategories].map((c) {
                final sel = _catFilter == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c),
                    selected: sel,
                    onSelected: (_) => setState(() => _catFilter = c),
                    backgroundColor: AppColors.card,
                    selectedColor: AppColors.gold.withValues(alpha: 0.15),
                    side: BorderSide(color: sel ? AppColors.gold.withValues(alpha: 0.5) : AppColors.border),
                    labelStyle: TextStyle(fontSize: 10, color: sel ? AppColors.gold : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                    showCheckmark: false, padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(8),
          if (!_adding) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.add, size: 14), label: const Text('Log Transaction'), onPressed: () => setState(() => _adding = true))),
              if (filtered.isNotEmpty) ...[
                const Gap(10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Text(egp(total), style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ),
          const Gap(8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _TxTile(tx: filtered[i]),
                  ),
          ),
        ]);
      },
    );
  }
}

class _AddTxForm extends StatelessWidget {
  const _AddTxForm({required this.desc, required this.amt, required this.cat, required this.acct, required this.date, required this.accounts, required this.onCatChange, required this.onAcctChange, required this.onDateChange, required this.onSave, required this.onCancel});
  final TextEditingController desc, amt;
  final String cat, acct;
  final DateTime date;
  final List<String> accounts;
  final void Function(String) onCatChange, onAcctChange;
  final void Function(DateTime) onDateChange;
  final VoidCallback onSave, onCancel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14), margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      AppTextField(controller: desc, label: 'Description', hint: 'What was this?'),
      const Gap(10),
      Row(children: [
        Expanded(child: AppTextField(controller: amt, label: 'Amount (EGP)', hint: '250', keyboardType: TextInputType.number)),
        const Gap(10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Account', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const Gap(5),
          DropdownButtonFormField<String>(
            initialValue: acct, onChanged: (v) => onAcctChange(v!),
            dropdownColor: AppColors.card,
            items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))).toList(),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true),
          ),
        ])),
      ]),
      const Gap(10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Category', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const Gap(5),
        DropdownButtonFormField<String>(
          initialValue: cat, onChanged: (v) => onCatChange(v!), dropdownColor: AppColors.card,
          items: AppConstants.txCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true),
        ),
      ]),
      const Gap(10),
      Row(children: [
        Expanded(child: ElevatedButton(onPressed: onSave, child: const Text('Save'))),
        const Gap(10),
        Expanded(child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
      ]),
    ]),
  );
}

class _TxTile extends ConsumerWidget {
  const _TxTile({required this.tx});
  final Transaction tx;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = AppColors.categoryColor(tx.category.toLowerCase());
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2))),
        const Gap(10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.description, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          Text('${tx.accountName} · ${tx.category} · ${DateFormat('dd MMM').format(tx.date)}', style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
        ])),
        Text('${tx.isIncome ? '+' : '-'}${egp(tx.amount)}', style: TextStyle(fontSize: 13, color: tx.isIncome ? AppColors.deen : AppColors.error, fontWeight: FontWeight.w600)),
        const Gap(6),
        IconButton(icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.error), onPressed: () => ref.read(transactionsProvider.notifier).delete(tx.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }
}
