import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/money_models.dart';
import '../data/repositories/money_repository.dart';

const _uuid = Uuid();

// ── Bank Accounts ──
final bankAccountsProvider =
    AsyncNotifierProvider<BankAccountsNotifier, List<BankAccount>>(
  BankAccountsNotifier.new,
);

class BankAccountsNotifier extends AsyncNotifier<List<BankAccount>> {
  @override
  Future<List<BankAccount>> build() =>
      MoneyRepository.instance.getBankAccounts();

  Future<void> upsert(BankAccount acc) async {
    await MoneyRepository.instance.upsertBankAccount(acc);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteBankAccount(id);
    state = AsyncData(state.value!.where((b) => b.id != id).toList());
  }

  Future<void> addNew() async {
    final acc = BankAccount(
      id: _uuid.v4(),
      name: 'New Bank',
      order: (state.value?.length ?? 0),
    );
    await upsert(acc);
  }
}

// ── Debts ──
final debtsProvider =
    AsyncNotifierProvider<DebtsNotifier, List<ExternalDebt>>(
  DebtsNotifier.new,
);

class DebtsNotifier extends AsyncNotifier<List<ExternalDebt>> {
  @override
  Future<List<ExternalDebt>> build() => MoneyRepository.instance.getDebts();

  Future<void> upsert(ExternalDebt debt) async {
    await MoneyRepository.instance.upsertDebt(debt);
    final existing = state.value?.indexWhere((d) => d.id == debt.id) ?? -1;
    if (existing >= 0) {
      final updated = [...state.value!];
      updated[existing] = debt;
      state = AsyncData(updated);
    } else {
      state = AsyncData([...state.value!, debt]);
    }
  }

  Future<void> add(ExternalDebt debt) => upsert(debt);

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteDebt(id);
    state = AsyncData(state.value!.where((d) => d.id != id).toList());
  }
}

// ── Investments ──
final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<Investment>>(
  InvestmentsNotifier.new,
);

class InvestmentsNotifier extends AsyncNotifier<List<Investment>> {
  @override
  Future<List<Investment>> build() =>
      MoneyRepository.instance.getInvestments();

  Future<void> add(Investment inv) async {
    await MoneyRepository.instance.upsertInvestment(inv);
    final existing = state.value?.indexWhere((i) => i.id == inv.id) ?? -1;
    if (existing >= 0) {
      final updated = [...state.value!];
      updated[existing] = inv;
      state = AsyncData(updated);
    } else {
      state = AsyncData([...state.value!, inv]);
    }
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteInvestment(id);
    state = AsyncData(state.value!.where((i) => i.id != id).toList());
  }
}

// ── Transactions ──
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() =>
      MoneyRepository.instance.getTransactions();

  Future<void> add(Transaction tx) async {
    await MoneyRepository.instance.addTransaction(tx);
    state = AsyncData([tx, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteTransaction(id);
    state = AsyncData(state.value!.where((t) => t.id != id).toList());
  }
}

// ── Cash on Hand ──
class CashOnHandNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() => MoneyRepository.instance.getCashOnHand();

  Future<void> set(double amount) async {
    await MoneyRepository.instance.setCashOnHand(amount);
    state = AsyncData(amount);
  }
}

final cashOnHandProvider =
    AsyncNotifierProvider<CashOnHandNotifier, double>(CashOnHandNotifier.new);

// ── Finance Summary (computed) ──
final financeSummaryProvider = Provider((ref) {
  final banks = ref.watch(bankAccountsProvider).value ?? [];
  final debts = ref.watch(debtsProvider).value ?? [];
  final txs = ref.watch(transactionsProvider).value ?? [];

  final totalCC = banks.fold(0.0, (s, b) => s + b.creditCardBalance);
  final totalLimit = banks.fold(0.0, (s, b) => s + b.creditCardLimit);
  final totalSavings = banks.fold(0.0, (s, b) => s + b.savingsBalance);
  final totalCurrent = banks.fold(0.0, (s, b) => s + b.currentBalance);
  final totalExtDebt = debts.fold(0.0, (s, d) => s + d.amount);
  final totalDebt = totalCC + totalExtDebt;
  final remainingLimit = totalLimit - totalCC;
  final todaySpend = txs
      .where((t) =>
          !t.isIncome &&
          t.date.year == DateTime.now().year &&
          t.date.month == DateTime.now().month &&
          t.date.day == DateTime.now().day)
      .fold(0.0, (s, t) => s + t.amount);

  return FinanceSummary(
    totalCC: totalCC,
    totalLimit: totalLimit,
    remainingLimit: remainingLimit,
    totalSavings: totalSavings,
    totalCurrent: totalCurrent,
    totalExtDebt: totalExtDebt,
    totalDebt: totalDebt,
    todaySpend: todaySpend,
  );
});
