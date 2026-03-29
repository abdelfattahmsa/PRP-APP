// ══════════════════════════════════════════════════════════════
// ALL FEATURE PROVIDERS
// Single file for Part 2 — split into per-feature files in prod
// ══════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../models/models.dart';

const _uuid = Uuid();

// ── SCHEDULE PROVIDER ─────────────────────────────────────────
final scheduleProvider =
    AsyncNotifierProviderFamily<ScheduleNotifier, List<ScheduleBlock>, String>(
  ScheduleNotifier.new,
);

class ScheduleNotifier
    extends FamilyAsyncNotifier<List<ScheduleBlock>, String> {
  @override
  Future<List<ScheduleBlock>> build(String mode) =>
      SupabaseService.instance.getScheduleBlocks(mode);

  Future<void> addBlock(ScheduleBlock block) async {
    await SupabaseService.instance.upsertBlock(block);
    ref.invalidateSelf();
  }

  Future<void> updateBlock(ScheduleBlock block) async {
    await SupabaseService.instance.upsertBlock(block);
    state = AsyncData(state.value!.map((b) => b.id == block.id ? block : b).toList());
  }

  Future<void> deleteBlock(String id) async {
    await SupabaseService.instance.deleteBlock(id);
    state = AsyncData(state.value!.where((b) => b.id != id).toList());
  }

  Future<void> reorder(List<ScheduleBlock> reordered) async {
    state = AsyncData(reordered);
    await SupabaseService.instance.reorderBlocks(reordered);
  }
}

// ── CALENDAR PROVIDER ─────────────────────────────────────────
final calendarProvider =
    AsyncNotifierProvider<CalendarNotifier, List<CalendarEvent>>(
  CalendarNotifier.new,
);

class CalendarNotifier extends AsyncNotifier<List<CalendarEvent>> {
  @override
  Future<List<CalendarEvent>> build() =>
      SupabaseService.instance.getCalendarEvents(
        from: DateTime(2026, 1, 1),
        to: DateTime(2027, 12, 31),
      );

  Future<void> addEvent(CalendarEvent event) async {
    final saved = await SupabaseService.instance.upsertEvent(event);
    state = AsyncData([...state.value!, saved]);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final saved = await SupabaseService.instance.upsertEvent(event);
    state = AsyncData(
        state.value!.map((e) => e.id == saved.id ? saved : e).toList());
  }

  Future<void> deleteEvent(String id) async {
    await SupabaseService.instance.deleteEvent(id);
    state = AsyncData(state.value!.where((e) => e.id != id).toList());
  }

  Future<void> markDone(String id, bool done) async {
    await SupabaseService.instance.markEventDone(id, done);
    state = AsyncData(
        state.value!.map((e) => e.id == id ? e.copyWith(isDone: done) : e).toList());
  }

  List<CalendarEvent> eventsForDay(DateTime day) {
    return (state.value ?? [])
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }
}

// ── FINANCE PROVIDERS ─────────────────────────────────────────
final bankAccountsProvider =
    AsyncNotifierProvider<BankAccountsNotifier, List<BankAccount>>(
  BankAccountsNotifier.new,
);

class BankAccountsNotifier extends AsyncNotifier<List<BankAccount>> {
  @override
  Future<List<BankAccount>> build() =>
      SupabaseService.instance.getBankAccounts();

  Future<void> upsert(BankAccount acc) async {
    await SupabaseService.instance.upsertBankAccount(acc);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteBankAccount(id);
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

final debtsProvider =
    AsyncNotifierProvider<DebtsNotifier, List<ExternalDebt>>(
  DebtsNotifier.new,
);

class DebtsNotifier extends AsyncNotifier<List<ExternalDebt>> {
  @override
  Future<List<ExternalDebt>> build() => SupabaseService.instance.getDebts();

  Future<void> add(ExternalDebt debt) async {
    await SupabaseService.instance.upsertDebt(debt);
    state = AsyncData([...state.value!, debt]);
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteDebt(id);
    state = AsyncData(state.value!.where((d) => d.id != id).toList());
  }
}

final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<Investment>>(
  InvestmentsNotifier.new,
);

class InvestmentsNotifier extends AsyncNotifier<List<Investment>> {
  @override
  Future<List<Investment>> build() =>
      SupabaseService.instance.getInvestments();

  Future<void> add(Investment inv) async {
    await SupabaseService.instance.upsertInvestment(inv);
    state = AsyncData([...state.value!, inv]);
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteInvestment(id);
    state = AsyncData(state.value!.where((i) => i.id != id).toList());
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() =>
      SupabaseService.instance.getTransactions();

  Future<void> add(Transaction tx) async {
    await SupabaseService.instance.addTransaction(tx);
    state = AsyncData([tx, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteTransaction(id);
    state = AsyncData(state.value!.where((t) => t.id != id).toList());
  }
}

// Finance summary computed provider
final financeSummaryProvider = Provider((ref) {
  final banks = ref.watch(bankAccountsProvider).valueOrNull ?? [];
  final debts = ref.watch(debtsProvider).valueOrNull ?? [];
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];

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

// ── HABITS PROVIDER ───────────────────────────────────────────
final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() => SupabaseService.instance.getHabits();

  Future<void> add(Habit habit) async {
    await SupabaseService.instance.upsertHabit(habit);
    state = AsyncData([...state.value!, habit]);
  }

  Future<void> update(Habit habit) async {
    await SupabaseService.instance.upsertHabit(habit);
    state = AsyncData(
        state.value!.map((h) => h.id == habit.id ? habit : h).toList());
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteHabit(id);
    state = AsyncData(state.value!.where((h) => h.id != id).toList());
  }

  Future<void> toggle(String id, String dateKey) async {
    final habits = state.value!;
    final habit = habits.firstWhere((h) => h.id == id);
    final wasDone = habit.history[dateKey] ?? false;
    await SupabaseService.instance.toggleHabitDay(id, dateKey, !wasDone);
    // Optimistic update
    final newHistory = Map<String, bool>.from(habit.history);
    newHistory[dateKey] = !wasDone;
    final updated = habit.copyWith(history: newHistory);
    final newStreak = updated.calculateStreak();
    final withStreak = updated.copyWith(
      streak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    );
    state = AsyncData(habits.map((h) => h.id == id ? withStreak : h).toList());
  }
}

// Derived: today's completion %
final habitsTodayProvider = Provider((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? [];
  if (habits.isEmpty) return (done: 0, total: 0, pct: 0.0);
  final done = habits.where((h) => h.isDoneToday).length;
  return (done: done, total: habits.length, pct: done / habits.length);
});

// ── GOALS PROVIDER ────────────────────────────────────────────
final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() => SupabaseService.instance.getGoals();

  Future<void> add(Goal goal) async {
    final saved = await SupabaseService.instance.upsertGoal(goal);
    state = AsyncData([...state.value!, saved]);
  }

  Future<void> update(Goal goal) async {
    final saved = await SupabaseService.instance.upsertGoal(goal);
    state = AsyncData(
        state.value!.map((g) => g.id == saved.id ? saved : g).toList());
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteGoal(id);
    state = AsyncData(state.value!.where((g) => g.id != id).toList());
  }

  Future<void> setProgress(String id, int progress) async {
    final goal = state.value!.firstWhere((g) => g.id == id);
    await update(goal.copyWith(progress: progress));
  }

  Future<void> setStatus(String id, String status) async {
    final goal = state.value!.firstWhere((g) => g.id == id);
    await update(goal.copyWith(status: status));
  }
}

// ── FOCUS PROVIDER ────────────────────────────────────────────
final focusSessionsProvider =
    AsyncNotifierProvider<FocusSessionsNotifier, List<FocusSession>>(
  FocusSessionsNotifier.new,
);

class FocusSessionsNotifier extends AsyncNotifier<List<FocusSession>> {
  @override
  Future<List<FocusSession>> build() =>
      SupabaseService.instance.getFocusSessions();

  Future<void> add(FocusSession session) async {
    await SupabaseService.instance.addFocusSession(session);
    state = AsyncData([session, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteFocusSession(id);
    state = AsyncData(state.value!.where((s) => s.id != id).toList());
  }
}

// Focus timer state (ephemeral — not persisted)
class FocusTimerState {
  const FocusTimerState({
    this.secondsLeft = 25 * 60,
    this.isRunning = false,
    this.mode = 'focus',
    this.focusDuration = 25,
    this.breakDuration = 5,
    this.selectedBlockLabel = '',
    this.selectedBlockCategory = 'rest',
    this.note = '',
    this.startedAt,
  });

  final int secondsLeft;
  final bool isRunning;
  final String mode;
  final int focusDuration;
  final int breakDuration;
  final String selectedBlockLabel;
  final String selectedBlockCategory;
  final String note;
  final DateTime? startedAt;

  int get totalSeconds =>
      (mode == 'focus' ? focusDuration : breakDuration) * 60;
  double get progress => 1.0 - (secondsLeft / totalSeconds);

  FocusTimerState copyWith({
    int? secondsLeft, bool? isRunning, String? mode,
    int? focusDuration, int? breakDuration,
    String? selectedBlockLabel, String? selectedBlockCategory,
    String? note, DateTime? startedAt,
  }) =>
      FocusTimerState(
        secondsLeft: secondsLeft ?? this.secondsLeft,
        isRunning: isRunning ?? this.isRunning,
        mode: mode ?? this.mode,
        focusDuration: focusDuration ?? this.focusDuration,
        breakDuration: breakDuration ?? this.breakDuration,
        selectedBlockLabel: selectedBlockLabel ?? this.selectedBlockLabel,
        selectedBlockCategory: selectedBlockCategory ?? this.selectedBlockCategory,
        note: note ?? this.note,
        startedAt: startedAt ?? this.startedAt,
      );
}

class FocusTimerNotifier extends Notifier<FocusTimerState> {
  @override
  FocusTimerState build() => const FocusTimerState();

  void start() {
    state = state.copyWith(isRunning: true, startedAt: DateTime.now());
  }

  void pause() => state = state.copyWith(isRunning: false);

  void reset() => state = state.copyWith(
        secondsLeft: state.totalSeconds,
        isRunning: false,
        startedAt: null,
      );

  void tick() {
    if (!state.isRunning) return;
    if (state.secondsLeft <= 1) {
      state = state.copyWith(secondsLeft: 0, isRunning: false);
    } else {
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    }
  }

  void setMode(String mode) => state = state.copyWith(
        mode: mode,
        secondsLeft: (mode == 'focus' ? state.focusDuration : state.breakDuration) * 60,
        isRunning: false,
        startedAt: null,
      );

  void setDuration(int focus, int brk) => state = state.copyWith(
        focusDuration: focus,
        breakDuration: brk,
        secondsLeft: (state.mode == 'focus' ? focus : brk) * 60,
      );

  void selectBlock(String label, String category) =>
      state = state.copyWith(selectedBlockLabel: label, selectedBlockCategory: category);

  void setNote(String note) => state = state.copyWith(note: note);
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);
