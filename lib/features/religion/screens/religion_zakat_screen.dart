import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

// Nisab = value of 85g gold or 595g silver
// Using conservative gold-based nisab; user can update the price.
const _kNisabGoldGrams = 85.0;
const _kZakatRate = 0.025; // 2.5%

class ReligionZakatScreen extends StatefulWidget {
  const ReligionZakatScreen({super.key});

  @override
  State<ReligionZakatScreen> createState() => _ReligionZakatScreenState();
}

class _ReligionZakatScreenState extends State<ReligionZakatScreen> {
  final _goldPriceCtrl     = TextEditingController(text: '');
  final _cashCtrl          = TextEditingController(text: '');
  final _goldWeightCtrl    = TextEditingController(text: '');
  final _silverWeightCtrl  = TextEditingController(text: '');
  final _stocksCtrl        = TextEditingController(text: '');
  final _businessCtrl      = TextEditingController(text: '');
  final _loansGivenCtrl    = TextEditingController(text: '');
  final _loansOwedCtrl     = TextEditingController(text: '');

  String _currency = 'EGP';

  double _parse(TextEditingController c) => double.tryParse(c.text) ?? 0;

  double get _goldPricePerGram  => _parse(_goldPriceCtrl);
  double get _nisabValue        => _kNisabGoldGrams * _goldPricePerGram;
  double get _totalAssets =>
      _parse(_cashCtrl) +
      (_parse(_goldWeightCtrl) * _goldPricePerGram) +
      (_parse(_silverWeightCtrl) * _silverPriceEstimate) +
      _parse(_stocksCtrl) +
      _parse(_businessCtrl) +
      _parse(_loansGivenCtrl);
  // Deduct debts owed
  double get _netZakatable => (_totalAssets - _parse(_loansOwedCtrl)).clamp(0, double.infinity);
  double get _zakatDue      => _netZakatable >= _nisabValue ? _netZakatable * _kZakatRate : 0;
  bool get _isAboveNisab    => _nisabValue > 0 && _netZakatable >= _nisabValue;

  // Rough silver price estimate (user typically uses gold nisab)
  double get _silverPriceEstimate => _goldPricePerGram * 0.013; // ~1/77 of gold

  @override
  void dispose() {
    _goldPriceCtrl.dispose(); _cashCtrl.dispose(); _goldWeightCtrl.dispose();
    _silverWeightCtrl.dispose(); _stocksCtrl.dispose(); _businessCtrl.dispose();
    _loansGivenCtrl.dispose(); _loansOwedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final hasGoldPrice = _goldPricePerGram > 0;
    final result = _zakatDue;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Zakat Calculator',
              subtitle: 'Check if Zakat is due on your wealth',
            ),
            const Gap(16),

            // ── Info banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.deen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.deen.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 18)),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      'Zakat is due at 2.5% on zakatable wealth held for one lunar year (hawl) above the nisab threshold (~85g of gold).',
                      style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // ── Currency picker ─────────────────────────────────
            Row(
              children: [
                const SectionHeader('Currency'),
                const Spacer(),
                DropdownButton<String>(
                  value: _currency,
                  underline: const SizedBox.shrink(),
                  items: ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'].map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)),
                  ).toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ],
            ),
            const Gap(4),

            // ── Gold price input ────────────────────────────────
            SectionCard(children: [
              _AmountTile(
                label: 'Gold Price per Gram ($_currency)',
                hint: 'Current market price',
                ctrl: _goldPriceCtrl,
                icon: '🥇',
                onChanged: () => setState(() {}),
              ),
            ]),
            const Gap(8),
            if (hasGoldPrice)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Nisab (85g × $_currency ${_goldPricePerGram.toStringAsFixed(0)}) = $_currency ${_nisabValue.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            const Gap(8),

            // ── Assets ──────────────────────────────────────────
            const SectionHeader('Your Assets'),
            const Gap(12),
            SectionCard(children: [
              _AmountTile(label: 'Cash, Bank & Savings ($_currency)', hint: '0.00', ctrl: _cashCtrl, icon: '💵', onChanged: () => setState(() {})),
              Divider(height: 1, color: borderColor),
              _AmountTile(label: 'Gold Owned (grams)', hint: '0', ctrl: _goldWeightCtrl, icon: '🥇', onChanged: () => setState(() {})),
              Divider(height: 1, color: borderColor),
              _AmountTile(label: 'Silver Owned (grams)', hint: '0', ctrl: _silverWeightCtrl, icon: '🥈', onChanged: () => setState(() {})),
              Divider(height: 1, color: borderColor),
              _AmountTile(label: 'Stocks & Investments ($_currency)', hint: '0.00', ctrl: _stocksCtrl, icon: '📈', onChanged: () => setState(() {})),
              Divider(height: 1, color: borderColor),
              _AmountTile(label: 'Business Inventory ($_currency)', hint: '0.00', ctrl: _businessCtrl, icon: '🏪', onChanged: () => setState(() {})),
              Divider(height: 1, color: borderColor),
              _AmountTile(label: 'Loans Given (owed to you)', hint: '0.00', ctrl: _loansGivenCtrl, icon: '🤝', onChanged: () => setState(() {})),
            ]),
            const Gap(16),

            // ── Liabilities ─────────────────────────────────────
            const SectionHeader('Deduct Debts'),
            const Gap(12),
            SectionCard(children: [
              _AmountTile(label: 'Loans & Debts You Owe ($_currency)', hint: '0.00', ctrl: _loansOwedCtrl, icon: '📉', onChanged: () => setState(() {})),
            ]),
            const Gap(24),

            // ── Result ──────────────────────────────────────────
            if (hasGoldPrice) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    (_isAboveNisab ? AppColors.deen : textSecondary).withValues(alpha: 0.12),
                    (_isAboveNisab ? AppColors.deen : textSecondary).withValues(alpha: 0.04),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_isAboveNisab ? AppColors.deen : textSecondary).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isAboveNisab ? '✅ Zakat is Due' : '⚖️ Below Nisab',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _isAboveNisab ? AppColors.deen : textSecondary,
                          ),
                    ),
                    const Gap(16),
                    _ResultRow(
                      label: 'Net Zakatable Wealth',
                      value: '$_currency ${_netZakatable.toStringAsFixed(2)}',
                      textSecondary: textSecondary,
                    ),
                    const Gap(6),
                    _ResultRow(
                      label: 'Nisab Threshold',
                      value: '$_currency ${_nisabValue.toStringAsFixed(2)}',
                      textSecondary: textSecondary,
                    ),
                    const Gap(12),
                    Divider(color: borderColor),
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zakat Due (2.5%)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '$_currency ${result.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _isAboveNisab ? AppColors.deen : textSecondary,
                              ),
                        ),
                      ],
                    ),
                    if (!_isAboveNisab) ...[
                      const Gap(8),
                      Text(
                        'Your wealth is below the nisab threshold. No Zakat is due at this time.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'Enter the current gold price per gram to calculate your nisab and Zakat due.',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const Gap(16),
            Text(
              'Note: This is an estimate. Consult a qualified scholar for your specific situation.',
              style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.icon,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final String icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const Gap(12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Gap(8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, required this.textSecondary});
  final String label;
  final String value;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
