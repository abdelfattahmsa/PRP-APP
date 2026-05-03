import 'package:equatable/equatable.dart';

// ══ ACCOUNT TYPE ══════════════════════════════════════════════════
enum AccountType { savings, current, digitalWallet }

const kDigitalWallets = [
  'PayPal', 'Payoneer', 'Wise', 'Vodafone Cash',
  'FawryPay', 'InstaPay', 'OPay', 'Other',
];

// ══ INSTALLMENT PROVIDERS ════════════════════════════════════════
const kInstallmentProviders = [
  'Valu', 'Tru (TruValue)', 'Contact Finance',
  'Sympl', 'Aman', 'Bank Takseet', 'Other',
];

// ══ BANK ACCOUNT ══════════════════════════════════════════════════
class BankAccount extends Equatable {
  const BankAccount({
    required this.id,
    required this.name,
    this.creditCardBalance = 0,
    this.creditCardLimit = 0,
    this.minimumPayment = 0,
    this.savingsBalance = 0,
    this.currentBalance = 0,
    this.order = 0,
    this.currency = 'EGP',
    this.accountType = AccountType.savings,
    this.walletProvider,
  });

  final String id;
  final String name;
  final double creditCardBalance;
  final double creditCardLimit;
  final double minimumPayment;
  final double savingsBalance;
  final double currentBalance;
  final int order;
  final String currency;
  final AccountType accountType;
  final String? walletProvider;

  double get remainingCreditLimit => creditCardLimit - creditCardBalance;
  bool get isOverLimit => remainingCreditLimit < 0;
  bool get hasCard => creditCardLimit > 0;
  bool get isDigitalWallet => accountType == AccountType.digitalWallet;
  double get totalBalance => currentBalance + savingsBalance;

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    AccountType aType = AccountType.savings;
    try {
      final raw = json['account_type'] as String?;
      if (raw == 'current') aType = AccountType.current;
      if (raw == 'digitalWallet') aType = AccountType.digitalWallet;
    } catch (_) {}
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      creditCardBalance: (json['cc_balance'] as num?)?.toDouble() ?? 0,
      creditCardLimit: (json['cc_limit'] as num?)?.toDouble() ?? 0,
      minimumPayment: (json['minimum_payment'] as num?)?.toDouble() ?? 0,
      savingsBalance: (json['savings_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      order: json['order'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'EGP',
      accountType: aType,
      walletProvider: json['wallet_provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cc_balance': creditCardBalance,
        'cc_limit': creditCardLimit,
        'savings_balance': savingsBalance,
        'current_balance': currentBalance,
        'order': order,
        'currency': currency,
        'account_type': accountType.name,
        'wallet_provider': walletProvider,
      };

  BankAccount copyWith({
    String? name,
    double? creditCardBalance,
    double? creditCardLimit,
    double? minimumPayment,
    double? savingsBalance,
    double? currentBalance,
    String? currency,
    AccountType? accountType,
    String? walletProvider,
    bool clearWalletProvider = false,
  }) =>
      BankAccount(
        id: id,
        name: name ?? this.name,
        creditCardBalance: creditCardBalance ?? this.creditCardBalance,
        creditCardLimit: creditCardLimit ?? this.creditCardLimit,
        minimumPayment: minimumPayment ?? this.minimumPayment,
        savingsBalance: savingsBalance ?? this.savingsBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        order: order,
        currency: currency ?? this.currency,
        accountType: accountType ?? this.accountType,
        walletProvider: clearWalletProvider ? null : (walletProvider ?? this.walletProvider),
      );

  @override
  List<Object?> get props => [id, name];
}

// ══ CREDIT CARD ═══════════════════════════════════════════════════
class CreditCard extends Equatable {
  const CreditCard({
    required this.id,
    required this.name,
    this.bank = '',
    this.balance = 0,
    this.limit = 0,
    this.minPaymentPct = 0.05,
    this.apr = 0,
    this.statementDay = 25,
    this.dueDay = 5,
    this.currency = 'EGP',
    this.order = 0,
  });

  final String id;
  final String name;     // Card nickname, e.g. "CIB Visa Platinum"
  final String bank;     // Bank name, e.g. "CIB"
  final double balance;  // Current outstanding balance
  final double limit;    // Credit limit
  final double minPaymentPct; // e.g. 0.05 = 5% of balance
  final double apr;      // Annual Percentage Rate, e.g. 0.36 = 36%
  final int statementDay; // Day of month statement closes (1-28)
  final int dueDay;      // Day of month payment due (1-28)
  final String currency;
  final int order;

  double get remainingLimit => limit - balance;
  double get utilizationPct => limit > 0 ? balance / limit : 0;
  double get minPaymentAmount => balance * minPaymentPct;
  bool get isOverLimit => remainingLimit < 0;
  double get monthlyInterest => balance * (apr / 12);

  DateTime get nextDueDate {
    final now = DateTime.now();
    final day = dueDay.clamp(1, 28);
    var due = DateTime(now.year, now.month, day);
    if (due.isBefore(now)) due = DateTime(now.year, now.month + 1, day);
    return due;
  }

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
        id: json['id'] as String,
        name: json['name'] as String,
        bank: json['bank'] as String? ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        limit: (json['limit'] as num?)?.toDouble() ?? 0,
        minPaymentPct: (json['min_payment_pct'] as num?)?.toDouble() ?? 0.05,
        apr: (json['apr'] as num?)?.toDouble() ?? 0,
        statementDay: json['statement_day'] as int? ?? 25,
        dueDay: json['due_day'] as int? ?? 5,
        currency: json['currency'] as String? ?? 'EGP',
        order: json['order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bank': bank,
        'balance': balance,
        'limit': limit,
        'min_payment_pct': minPaymentPct,
        'apr': apr,
        'statement_day': statementDay,
        'due_day': dueDay,
        'currency': currency,
        'order': order,
      };

  CreditCard copyWith({
    String? name,
    String? bank,
    double? balance,
    double? limit,
    double? minPaymentPct,
    double? apr,
    int? statementDay,
    int? dueDay,
    String? currency,
    int? order,
  }) =>
      CreditCard(
        id: id,
        name: name ?? this.name,
        bank: bank ?? this.bank,
        balance: balance ?? this.balance,
        limit: limit ?? this.limit,
        minPaymentPct: minPaymentPct ?? this.minPaymentPct,
        apr: apr ?? this.apr,
        statementDay: statementDay ?? this.statementDay,
        dueDay: dueDay ?? this.dueDay,
        currency: currency ?? this.currency,
        order: order ?? this.order,
      );

  @override
  List<Object?> get props => [id, name, bank];
}

// ══ INSTALLMENT PLAN ══════════════════════════════════════════════
class InstallmentPlan extends Equatable {
  const InstallmentPlan({
    required this.id,
    required this.description,
    required this.provider,
    required this.originalAmount,
    required this.monthlyPayment,
    required this.totalMonths,
    this.paidMonths = 0,
    this.currency = 'EGP',
    this.startDate,
    this.notes,
  });

  final String id;
  final String description;   // e.g. "iPhone 16 Pro"
  final String provider;      // e.g. "Valu", "Tru (TruValue)", "Contact Finance"
  final double originalAmount;
  final double monthlyPayment;
  final int totalMonths;
  final int paidMonths;
  final String currency;
  final DateTime? startDate;
  final String? notes;

  int get remainingMonths => (totalMonths - paidMonths).clamp(0, totalMonths);
  double get remainingAmount => monthlyPayment * remainingMonths;
  double get paidAmount => monthlyPayment * paidMonths;
  double get progressPct => totalMonths > 0 ? paidMonths / totalMonths : 0;
  bool get isCompleted => paidMonths >= totalMonths;

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) => InstallmentPlan(
        id: json['id'] as String,
        description: json['description'] as String,
        provider: json['provider'] as String? ?? 'Other',
        originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0,
        monthlyPayment: (json['monthly_payment'] as num?)?.toDouble() ?? 0,
        totalMonths: json['total_months'] as int? ?? 1,
        paidMonths: json['paid_months'] as int? ?? 0,
        currency: json['currency'] as String? ?? 'EGP',
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'] as String)
            : null,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'provider': provider,
        'original_amount': originalAmount,
        'monthly_payment': monthlyPayment,
        'total_months': totalMonths,
        'paid_months': paidMonths,
        'currency': currency,
        'start_date': startDate?.toIso8601String().split('T').first,
        'notes': notes,
      };

  InstallmentPlan copyWith({
    String? description,
    String? provider,
    double? originalAmount,
    double? monthlyPayment,
    int? totalMonths,
    int? paidMonths,
    String? currency,
    DateTime? startDate,
    String? notes,
  }) =>
      InstallmentPlan(
        id: id,
        description: description ?? this.description,
        provider: provider ?? this.provider,
        originalAmount: originalAmount ?? this.originalAmount,
        monthlyPayment: monthlyPayment ?? this.monthlyPayment,
        totalMonths: totalMonths ?? this.totalMonths,
        paidMonths: paidMonths ?? this.paidMonths,
        currency: currency ?? this.currency,
        startDate: startDate ?? this.startDate,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [id, description, provider];
}

// ══ EXTERNAL DEBT ════════════════════════════════════════════════
class ExternalDebt extends Equatable {
  const ExternalDebt({
    required this.id,
    required this.source,
    required this.amount,
    this.notes,
    this.dueDate,
    this.isPaid = false,
  });

  final String id;
  final String source;
  final double amount;
  final String? notes;
  final DateTime? dueDate;
  final bool isPaid;

  factory ExternalDebt.fromJson(Map<String, dynamic> json) => ExternalDebt(
        id: json['id'] as String,
        source: (json['source'] ?? json['name'] ?? json['creditor']) as String? ?? 'Unknown',
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String?,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        isPaid: json['is_paid'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'amount': amount,
        'notes': notes,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'is_paid': isPaid,
      };

  @override
  List<Object?> get props => [id, source, amount];
}

// ══ INVESTMENT ════════════════════════════════════════════════════
class Investment extends Equatable {
  const Investment({
    required this.id,
    required this.type,
    required this.amount,
    required this.unit,
    this.ticker,
    this.quantity,
    this.purchasePrice,
    this.notes,
    this.purchaseDate,
  });

  final String id;
  final String type;
  final double amount;
  final String unit;
  final String? ticker;
  final double? quantity;
  final double? purchasePrice;
  final String? notes;
  final DateTime? purchaseDate;

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        unit: json['unit'] as String? ?? 'EGP',
        ticker: json['ticker'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble(),
        purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        purchaseDate: json['purchase_date'] != null
            ? DateTime.parse(json['purchase_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'unit': unit,
        'ticker': ticker,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'notes': notes,
        'purchase_date': purchaseDate?.toIso8601String().split('T').first,
      };

  @override
  List<Object?> get props => [id, type, amount, unit];
}

// ══ TRANSACTION ═══════════════════════════════════════════════════
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    required this.accountName,
    this.notes,
    this.isIncome = false,
    this.currency = 'EGP',
  });

  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String category;
  final String accountName;
  final String? notes;
  final bool isIncome;
  final String currency;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? json['title'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'General',
        accountName: json['account_name'] as String? ?? 'Cash',
        notes: json['notes'] as String?,
        isIncome: json['is_income'] as bool? ?? false,
        currency: json['currency'] as String? ?? 'EGP',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().split('T').first,
        'description': description,
        'amount': amount,
        'category': category,
        'account_name': accountName,
        'notes': notes,
        'is_income': isIncome,
        'currency': currency,
      };

  @override
  List<Object?> get props => [id, date, description, amount];
}

// ══ FINANCE SUMMARY (computed) ═══════════════════════════════════
class FinanceSummary {
  const FinanceSummary({
    required this.totalCC,
    required this.totalLimit,
    required this.remainingLimit,
    required this.totalSavings,
    required this.totalCurrent,
    required this.totalExtDebt,
    required this.totalDebt,
    required this.todaySpend,
    this.totalCCFromCards = 0,
    this.totalInstallments = 0,
    this.totalMonthlyObligation = 0,
  });
  final double totalCC, totalLimit, remainingLimit;
  final double totalSavings, totalCurrent;
  final double totalExtDebt, totalDebt;
  final double todaySpend;
  // New: from dedicated credit_cards table
  final double totalCCFromCards;
  final double totalInstallments;
  final double totalMonthlyObligation; // CC min payments + installment payments
}
