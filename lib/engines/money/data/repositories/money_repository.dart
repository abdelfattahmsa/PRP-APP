import '../../../../services/supabase_service.dart';
import '../models/money_models.dart';

/// Repository for all Money Engine data operations.
/// Delegates to SupabaseService for now; will support offline cache later.
class MoneyRepository {
  MoneyRepository._();
  static final instance = MoneyRepository._();

  final _service = SupabaseService.instance;

  // ── Bank Accounts ──
  Future<List<BankAccount>> getBankAccounts() => _service.getBankAccounts();
  Future<void> upsertBankAccount(BankAccount account) => _service.upsertBankAccount(account);
  Future<void> deleteBankAccount(String id) => _service.deleteBankAccount(id);

  // ── Debts ──
  Future<List<ExternalDebt>> getDebts() => _service.getDebts();
  Future<void> upsertDebt(ExternalDebt debt) => _service.upsertDebt(debt);
  Future<void> deleteDebt(String id) => _service.deleteDebt(id);

  // ── Investments ──
  Future<List<Investment>> getInvestments() => _service.getInvestments();
  Future<void> upsertInvestment(Investment inv) => _service.upsertInvestment(inv);
  Future<void> deleteInvestment(String id) => _service.deleteInvestment(id);

  // ── Transactions ──
  Future<List<Transaction>> getTransactions({String? category}) =>
      _service.getTransactions(category: category);
  Future<void> addTransaction(Transaction tx) => _service.addTransaction(tx);
  Future<void> deleteTransaction(String id) => _service.deleteTransaction(id);

  // ── Cash on Hand ──
  Future<double> getCashOnHand() => _service.getCashOnHand();
  Future<void> setCashOnHand(double amount) => _service.setCashOnHand(amount);
}
