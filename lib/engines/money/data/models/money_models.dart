import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String name;
  final double creditCardBalance;
  final double creditCardLimit;
  final double minimumPayment;
  final double savingsBalance;
  final double currentBalance;
  final int order;

  double get remainingCreditLimit => creditCardLimit - creditCardBalance;
  bool get isOverLimit => remainingCreditLimit < 0;
  bool get hasCard => creditCardLimit > 0;

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        creditCardBalance: (json['cc_balance'] as num?)?.toDouble() ?? 0,
        creditCardLimit: (json['cc_limit'] as num?)?.toDouble() ?? 0,
        minimumPayment: (json['minimum_payment'] as num?)?.toDouble() ?? 0,
        savingsBalance: (json['savings_balance'] as num?)?.toDouble() ?? 0,
        currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
        order: json['order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cc_balance': creditCardBalance,
        'cc_limit': creditCardLimit,
        'savings_balance': savingsBalance,
        'current_balance': currentBalance,
        'order': order,
      };

  BankAccount copyWith({
    String? name,
    double? creditCardBalance,
    double? creditCardLimit,
    double? minimumPayment,
    double? savingsBalance,
    double? currentBalance,
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
      );

  @override
  List<Object?> get props => [id, name];
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
  final String source;   // person or institution
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
  final String type;          // Gold, Silver, Stocks, etc.
  final double amount;        // Total value (manual or quantity × price)
  final String unit;          // EGP, USD, g, oz, shares
  final String? ticker;       // Stock/ETF ticker symbol e.g. "AAPL"
  final double? quantity;     // Number of units/shares
  final double? purchasePrice; // Price per unit at purchase
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
  });

  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String category;
  final String accountName;
  final String? notes;
  final bool isIncome;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? json['title'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'General',
        accountName: json['account_name'] as String? ?? 'Cash',
        notes: json['notes'] as String?,
        isIncome: json['is_income'] as bool? ?? false,
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
  });
  final double totalCC, totalLimit, remainingLimit;
  final double totalSavings, totalCurrent;
  final double totalExtDebt, totalDebt;
  final double todaySpend;
}
