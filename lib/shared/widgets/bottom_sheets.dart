import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../engines/money/data/models/money_models.dart';
import '../../engines/money/providers/money_providers.dart';
import '../../engines/health/data/models/health_models.dart';
import '../../engines/health/providers/health_providers.dart';
import '../../engines/time/data/models/time_models.dart';
import '../../engines/time/providers/time_providers.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════
// SHOW HELPERS
// ══════════════════════════════════════════════════════════════

Future<void> showAddTransaction(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTransactionSheet(),
  );
}

Future<void> showAddHabit(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddHabitSheet(),
  );
}

Future<void> showAddScheduleBlock(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddScheduleBlockSheet(),
  );
}

// ══════════════════════════════════════════════════════════════
// SHARED BOTTOM SHEET WRAPPER
// ══════════════════════════════════════════════════════════════

class _SheetWrapper extends StatelessWidget {
  const _SheetWrapper({required this.child, required this.title});
  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD TRANSACTION SHEET
// ══════════════════════════════════════════════════════════════

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet();

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = AppConstants.txCategories.first;
  String? _accountName;
  bool _isIncome = false;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tx = Transaction(
      id: _uuid.v4(),
      date: _date,
      description: _descCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      category: _category,
      accountName: _accountName ?? 'Cash',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isIncome: _isIncome,
    );

    try {
      await ref.read(transactionsProvider.notifier).add(tx);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;
    final accountsAsync = ref.watch(bankAccountsProvider);
    final accounts = accountsAsync.value ?? [];

    return _SheetWrapper(
      title: 'Add Transaction',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income / Expense toggle
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.card : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark ? AppColors.border : AppColors.lightBorder),
              ),
              child: Row(children: [
                for (final entry in [
                  (false, 'Expense', AppColors.error),
                  (true, 'Income', AppColors.success),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = entry.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isIncome == entry.$1
                              ? entry.$3.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _isIncome == entry.$1
                                ? entry.$3.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            entry.$2,
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isIncome == entry.$1
                                  ? entry.$3
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const Gap(16),

            // Description
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g. Lunch at restaurant',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const Gap(12),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixText: 'EGP  ',
                prefixStyle: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 13,
                  color: _isIncome ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                if (double.parse(v.trim()) <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const Gap(12),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.txCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const Gap(12),

            // Account
            if (accounts.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _accountName,
                decoration: const InputDecoration(labelText: 'Account'),
                hint: const Text('Select account'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Cash')),
                  ...accounts.map((a) =>
                      DropdownMenuItem(value: a.name, child: Text(a.name))),
                ],
                onChanged: (v) => setState(() => _accountName = v),
              )
            else
              TextFormField(
                initialValue: 'Cash',
                decoration: const InputDecoration(labelText: 'Account'),
                onChanged: (v) => _accountName = v,
              ),
            const Gap(12),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  '${_date.day.toString().padLeft(2, '0')} / '
                  '${_date.month.toString().padLeft(2, '0')} / '
                  '${_date.year}',
                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13),
                ),
              ),
            ),
            const Gap(12),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details...',
              ),
            ),
            const Gap(24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _isIncome ? AppColors.success : accent,
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
                        _isIncome ? 'Add Income' : 'Add Expense',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD HABIT SHEET
// ══════════════════════════════════════════════════════════════

const _habitIcons = [
  '🧘', '💧', '🏃', '🥗', '💊', '📚', '🌙', '🚶', '💪', '🧠',
  '🎯', '✅', '🌿', '🍎', '☕', '🧹', '✍️', '🎵', '🙏', '🌅',
];

class _AddHabitSheet extends ConsumerStatefulWidget {
  const _AddHabitSheet();

  @override
  ConsumerState<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<_AddHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _icon = '✅';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final habits = ref.read(habitsProvider).value ?? [];
    final habit = Habit(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      icon: _icon,
      order: habits.length,
    );

    try {
      await ref.read(habitsProvider.notifier).add(habit);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return _SheetWrapper(
      title: 'New Habit',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Habit name *',
                hintText: 'e.g. Morning meditation',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const Gap(16),

            // Icon picker
            Text(
              'Pick an icon',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                letterSpacing: 1,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _habitIcons.map((icon) {
                  final selected = icon == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? accent.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(24),

            // Selected preview
            Row(
              children: [
                Text(_icon, style: const TextStyle(fontSize: 28)),
                const Gap(12),
                Expanded(
                  child: Text(
                    _nameCtrl.text.isEmpty
                        ? 'Your habit name'
                        : _nameCtrl.text,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Gap(24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
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
                    : const Text(
                        'Create Habit',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD SCHEDULE BLOCK SHEET
// ══════════════════════════════════════════════════════════════

class _AddScheduleBlockSheet extends ConsumerStatefulWidget {
  const _AddScheduleBlockSheet();

  @override
  ConsumerState<_AddScheduleBlockSheet> createState() =>
      _AddScheduleBlockSheetState();
}

class _AddScheduleBlockSheetState
    extends ConsumerState<_AddScheduleBlockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = 'work';
  String _scheduleMode = 'normal';
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _duration = 60;
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String get _timeStr =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final block = ScheduleBlock(
      id: _uuid.v4(),
      scheduleMode: _scheduleMode,
      time: _timeStr,
      label: _labelCtrl.text.trim(),
      categoryKey: _category,
      duration: '${_duration}m',
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      order: 0,
    );

    try {
      await ScheduleActions.instance.addBlock(ref, block);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return _SheetWrapper(
      title: 'Add Schedule Block',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            TextFormField(
              controller: _labelCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Block label *',
                hintText: 'e.g. Deep Work',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const Gap(12),

            // Time
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start time',
                  suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                ),
                child: Text(
                  _timeStr,
                  style: const TextStyle(
                      fontFamily: 'IBMPlexMono', fontSize: 13),
                ),
              ),
            ),
            const Gap(12),

            // Duration
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: '$_duration',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                  ),
                  onChanged: (v) => _duration = int.tryParse(v) ?? _duration,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 5) return 'Min 5 min';
                    return null;
                  },
                ),
              ),
            ]),
            const Gap(12),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.categoryKeys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const Gap(12),

            // Schedule mode
            DropdownButtonFormField<String>(
              value: _scheduleMode,
              decoration: const InputDecoration(labelText: 'Schedule mode'),
              items: AppConstants.scheduleModes
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(m[0].toUpperCase() + m.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _scheduleMode = v!),
            ),
            const Gap(12),

            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
            const Gap(24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
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
                    : const Text(
                        'Add Block',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
