import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/money/data/models/money_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../services/market_data_service.dart';
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

            final baseCurrencyAsync = ref.watch(baseCurrencyProvider);
            final baseCurrency = baseCurrencyAsync.asData?.value ?? 'USD';

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
                          '${fmt.format(total)} $baseCurrency',
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

                // Live Market Prices
                const _MarketPricesCard(),
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
    if (t.contains('stock') || t.contains('share') || t.contains('equity')) return AppColors.learn;
    if (t.contains('bond') || t.contains('bill')) return AppColors.learn;
    if (t.contains('real estate')) return AppColors.success;
    return AppColors.learn;
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
          color: AppColors.error.withValues(alpha: 0.15),
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
                  color: _colorFor(inv.type).withValues(alpha: 0.15),
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
                  if (inv.ticker != null)
                    _LivePriceBadge(ticker: inv.ticker!)
                  else
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

class _LivePriceBadge extends ConsumerWidget {
  const _LivePriceBadge({required this.ticker});
  final String ticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceAsync = ref.watch(stockPriceProvider(ticker));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return priceAsync.when(
      loading: () => Text(ticker,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: secondary)),
      error: (_, __) => Text(ticker,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: secondary)),
      data: (price) => price != null
          ? Text(
              '\$$ticker  ${price.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontFamily: 'Roboto', fontSize: 10,
                  color: AppColors.success, fontWeight: FontWeight.w600),
            )
          : Text(ticker,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: secondary)),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LIVE MARKET PRICES CARD
// ══════════════════════════════════════════════════════════════

class _MarketPricesCard extends ConsumerWidget {
  const _MarketPricesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metalsAsync = ref.watch(metalPricesProvider);
    final cryptoAsync = ref.watch(cryptoPricesProvider);
    final fxAsync = ref.watch(fxRatesProvider);
    final baseCurrencyAsync = ref.watch(baseCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final fmt = NumberFormat('#,##0.##', 'en_US');

    final baseCurrency = baseCurrencyAsync.asData?.value ?? 'USD';
    final rates = fxAsync.asData?.value ?? {};

    // Convert USD price to user's base currency
    double toBase(double usd) {
      if (baseCurrency == 'USD') return usd;
      final toRate = rates[baseCurrency] ?? 1.0;
      return usd * toRate;
    }

    String fmtChange(double change, {bool isPct = false}) {
      final sign = change >= 0 ? '+' : '';
      if (isPct) return '$sign${change.toStringAsFixed(2)}%';
      return '$sign${fmt.format(change)}';
    }

    Color changeColor(double change) =>
        change >= 0 ? AppColors.success : AppColors.error;

    Widget priceRow(String label, String emoji, double usdPrice, double change,
        {bool isPct = false}) {
      final basePrice = toBase(usdPrice);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const Gap(8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${fmt.format(basePrice)} $baseCurrency',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              fmtChange(change, isPct: isPct),
              style: TextStyle(
                fontSize: 11,
                color: changeColor(change),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    Widget keyRateChip(String code, Map<String, double> rates) {
      if (code == 'USD' || rates[code] == null) return const SizedBox.shrink();
      final rateVsUsd = rates[code]!;
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.lightCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? AppColors.border : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(code,
                style: TextStyle(
                    fontSize: 10,
                    color: textSecondary,
                    fontWeight: FontWeight.w600)),
            Text(fmt.format(rateVsUsd),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 16, color: accent),
                const Gap(8),
                Text(
                  'Live Market Prices',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const Spacer(),
                Text(
                  'Live • USD base',
                  style: TextStyle(fontSize: 10, color: textSecondary),
                ),
              ],
            ),
            const Gap(12),

            // ── Metals ────────────────────────────────────────────
            Text('Precious Metals',
                style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600)),
            const Gap(6),
            metalsAsync.when(
              loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)))),
              error: (_, __) => Text('Unable to load metal prices',
                  style: TextStyle(fontSize: 12, color: textSecondary)),
              data: (metals) => metals == null
                  ? Text('Metal prices unavailable',
                      style: TextStyle(fontSize: 12, color: textSecondary))
                  : Column(
                      children: [
                        priceRow('Gold', '🟡', metals.goldUsd, metals.goldChange),
                        priceRow('Silver', '⬜', metals.silverUsd,
                            metals.silverChange),
                      ],
                    ),
            ),
            const Gap(12),

            // ── Crypto ────────────────────────────────────────────
            Text('Crypto',
                style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600)),
            const Gap(6),
            cryptoAsync.when(
              loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)))),
              error: (_, __) => Text('Unable to load crypto prices',
                  style: TextStyle(fontSize: 12, color: textSecondary)),
              data: (cryptos) => cryptos.isEmpty
                  ? Text('Crypto prices unavailable',
                      style: TextStyle(fontSize: 12, color: textSecondary))
                  : Column(
                      children: cryptos.map((c) {
                        final emoji = c.symbol == 'BTC'
                            ? '₿'
                            : c.symbol == 'ETH'
                                ? 'Ξ'
                                : c.symbol == 'SOL'
                                    ? '◎'
                                    : '◆';
                        return priceRow(
                            '${c.name} (${c.symbol})', emoji, c.usdPrice, c.change24h,
                            isPct: true);
                      }).toList(),
                    ),
            ),
            const Gap(12),

            // ── Key FX Rates ────────────────────────────────────
            Text('Key Rates vs USD',
                style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600)),
            const Gap(8),
            fxAsync.when(
              loading: () => const SizedBox(height: 30),
              error: (_, __) => const SizedBox.shrink(),
              data: (rates) => Wrap(
                children: ['EGP', 'EUR', 'GBP', 'SAR', 'AED', 'JPY']
                    .map((c) => keyRateChip(c, rates))
                    .toList(),
              ),
            ),
          ],
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

const _currencyUnits = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];
const _nonCurrencyUnits = ['g', 'oz', 'BTC', 'shares'];

List<String> _buildUnits(String baseCurrency) {
  final currencies = [
    baseCurrency,
    ..._currencyUnits.where((c) => c != baseCurrency),
  ];
  return [...currencies, ..._nonCurrencyUnits];
}

class _InvestmentSheet extends ConsumerStatefulWidget {
  const _InvestmentSheet({this.existing});
  final Investment? existing;

  @override
  ConsumerState<_InvestmentSheet> createState() => _InvestmentSheetState();
}

class _InvestmentSheetState extends ConsumerState<_InvestmentSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tickerCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  String _type = _investmentTypes.first;
  String? _unit; // null until base currency is resolved
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final inv = widget.existing!;
      _type = _investmentTypes.contains(inv.type) ? inv.type : _investmentTypes.first;
      _unit = inv.unit;
      _amountCtrl.text = inv.amount.toString();
      _notesCtrl.text = inv.notes ?? '';
      _tickerCtrl.text = inv.ticker ?? '';
      if (inv.quantity != null) _quantityCtrl.text = inv.quantity.toString();
      if (inv.purchasePrice != null) _purchasePriceCtrl.text = inv.purchasePrice.toString();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _tickerCtrl.dispose();
    _quantityCtrl.dispose();
    _purchasePriceCtrl.dispose();
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
      unit: _unit ?? 'EGP',
      ticker: _tickerCtrl.text.trim().isEmpty ? null : _tickerCtrl.text.trim().toUpperCase(),
      quantity: double.tryParse(_quantityCtrl.text.trim()),
      purchasePrice: double.tryParse(_purchasePriceCtrl.text.trim()),
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
    final baseCurrency =
        ref.watch(baseCurrencyProvider).asData?.value ?? 'EGP';
    final units = _buildUnits(baseCurrency);
    // Initialise _unit lazily once baseCurrency is known
    _unit ??= baseCurrency;
    // Guard: if stored unit is not in list, snap to baseCurrency
    if (!units.contains(_unit)) {
      // Use post-frame to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _unit = baseCurrency));
    }
    final safeUnit = units.contains(_unit) ? _unit! : baseCurrency;

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
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
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
              initialValue: _type,
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
                    key: ValueKey(baseCurrency),
                    initialValue: safeUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: units
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const Gap(12),

            if (_type.toLowerCase().contains('stock') ||
                _type.toLowerCase().contains('etf') ||
                _type.toLowerCase().contains('crypto')) ...[
              const Gap(12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _tickerCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Ticker (e.g. AAPL)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: TextField(
                    controller: _quantityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ]),
              const Gap(12),
              TextField(
                controller: _purchasePriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Purchase price per unit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
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