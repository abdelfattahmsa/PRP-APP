import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../shared/models/models.dart';
import '../engines/ideas/data/models/idea_models.dart';
import '../engines/health/providers/fasting_provider.dart';

const _uuidGen = Uuid();

/// Central service for all Supabase operations.
/// Each feature gets its own method group.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  String get _uid => _db.auth.currentUser!.id;

  // ── AUTH ──────────────────────────────────────────────────────
  Stream<AuthState> get authStateStream => _db.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (res.user != null) {
      await _db.from('profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'full_name': fullName,
      });
      await _seedDefaultData(res.user!.id);
    }
    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _db.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _db.auth.signOut();

  Future<void> resetPassword(String email) =>
      _db.auth.resetPasswordForEmail(email);

  Future<AppUser?> getProfile() async {
    final res =
        await _db.from('profiles').select().eq('id', _uid).maybeSingle();
    return res != null ? AppUser.fromJson(res) : null;
  }

  Future<void> updateProfile(AppUser user) =>
      _db.from('profiles').update(user.toJson()).eq('id', _uid);

  // ── SCHEDULE ──────────────────────────────────────────────────
  Future<List<ScheduleBlock>> getScheduleBlocks(String mode) async {
    final res = await _db
        .from('schedule_blocks')
        .select()
        .eq('user_id', _uid)
        .eq('schedule_mode', mode)
        .order('order');
    return res.map((j) => ScheduleBlock.fromJson(j)).toList();
  }

  Future<void> upsertBlock(ScheduleBlock block) => _db
      .from('schedule_blocks')
      .upsert({...block.toJson(), 'user_id': _uid});

  Future<void> deleteBlock(String id) =>
      _db.from('schedule_blocks').delete().eq('id', id).eq('user_id', _uid);

  Future<void> reorderBlocks(List<ScheduleBlock> blocks) async {
    final updates = blocks
        .asMap()
        .entries
        .map((e) => {'id': e.value.id, 'order': e.key, 'user_id': _uid})
        .toList();
    await _db.from('schedule_blocks').upsert(updates);
  }

  // ── CALENDAR ──────────────────────────────────────────────────
  Future<List<CalendarEvent>> getCalendarEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _db
        .from('calendar_events')
        .select()
        .eq('user_id', _uid);
    if (from != null) {
      query = query.gte('date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String().split('T').first);
    }
    final res = await query.order('date');
    return res.map((j) => CalendarEvent.fromJson(j)).toList();
  }

  Future<CalendarEvent> upsertEvent(CalendarEvent event) async {
    final res = await _db
        .from('calendar_events')
        .upsert({...event.toJson(), 'user_id': _uid})
        .select()
        .single();
    return CalendarEvent.fromJson(res);
  }

  Future<void> deleteEvent(String id) => _db
      .from('calendar_events')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  Future<void> markEventDone(String id, bool done) => _db
      .from('calendar_events')
      .update({'is_done': done})
      .eq('id', id)
      .eq('user_id', _uid);

  // ── FINANCE ───────────────────────────────────────────────────
  Future<List<BankAccount>> getBankAccounts() async {
    final res = await _db
        .from('bank_accounts')
        .select()
        .eq('user_id', _uid)
        .order('order');
    return res.map((j) => BankAccount.fromJson(j)).toList();
  }

  Future<void> upsertBankAccount(BankAccount account) => _db
      .from('bank_accounts')
      .upsert({...account.toJson(), 'user_id': _uid});

  Future<void> deleteBankAccount(String id) =>
      _db.from('bank_accounts').delete().eq('id', id).eq('user_id', _uid);

  Future<List<ExternalDebt>> getDebts() async {
    final res =
        await _db.from('debts').select().eq('user_id', _uid).order('amount', ascending: false);
    return res.map((j) => ExternalDebt.fromJson(j)).toList();
  }

  Future<void> upsertDebt(ExternalDebt debt) =>
      _db.from('debts').upsert({...debt.toJson(), 'user_id': _uid});

  Future<void> deleteDebt(String id) =>
      _db.from('debts').delete().eq('id', id).eq('user_id', _uid);

  Future<List<Investment>> getInvestments() async {
    final res = await _db.from('investments').select().eq('user_id', _uid);
    return res.map((j) => Investment.fromJson(j)).toList();
  }

  Future<void> upsertInvestment(Investment inv) =>
      _db.from('investments').upsert({...inv.toJson(), 'user_id': _uid});

  Future<void> deleteInvestment(String id) =>
      _db.from('investments').delete().eq('id', id).eq('user_id', _uid);

  Future<List<Transaction>> getTransactions({String? category}) async {
    var query =
        _db.from('transactions').select().eq('user_id', _uid);
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    final res = await query.order('date', ascending: false);
    return res.map((j) => Transaction.fromJson(j)).toList();
  }

  Future<void> addTransaction(Transaction tx) =>
      _db.from('transactions').insert({...tx.toJson(), 'user_id': _uid});

  Future<void> deleteTransaction(String id) =>
      _db.from('transactions').delete().eq('id', id).eq('user_id', _uid);

  // ── HABITS ────────────────────────────────────────────────────
  Future<List<Habit>> getHabits() async {
    final res = await _db
        .from('habits')
        .select()
        .eq('user_id', _uid)
        .eq('is_archived', false)
        .order('order');
    return res.map((j) => Habit.fromJson(j)).toList();
  }

  Future<void> upsertHabit(Habit habit) =>
      _db.from('habits').upsert({...habit.toJson(), 'user_id': _uid});

  Future<void> deleteHabit(String id) =>
      _db.from('habits').delete().eq('id', id).eq('user_id', _uid);

  Future<void> toggleHabitDay(String habitId, String dateKey, bool done) async {
    // Fetch current habit, update history, upsert
    final res = await _db
        .from('habits')
        .select()
        .eq('id', habitId)
        .eq('user_id', _uid)
        .single();
    final habit = Habit.fromJson(res);
    final newHistory = Map<String, bool>.from(habit.history);
    newHistory[dateKey] = done;
    final newStreak = habit.copyWith(history: newHistory).calculateStreak();
    await _db.from('habits').update({
      'history': newHistory,
      'streak': newStreak,
      'longest_streak': newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    }).eq('id', habitId).eq('user_id', _uid);
  }

  // ── GOALS ─────────────────────────────────────────────────────
  Future<List<Goal>> getGoals() async {
    final res = await _db
        .from('goals')
        .select()
        .eq('user_id', _uid)
        .order('target_date');
    return res.map((j) => Goal.fromJson(j)).toList();
  }

  Future<Goal> upsertGoal(Goal goal) async {
    final res = await _db
        .from('goals')
        .upsert({...goal.toJson(), 'user_id': _uid})
        .select()
        .single();
    return Goal.fromJson(res);
  }

  Future<void> deleteGoal(String id) =>
      _db.from('goals').delete().eq('id', id).eq('user_id', _uid);

  // ── FOCUS SESSIONS ────────────────────────────────────────────
  Future<List<FocusSession>> getFocusSessions({int limit = 100}) async {
    final res = await _db
        .from('focus_sessions')
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .limit(limit);
    return res.map((j) => FocusSession.fromJson(j)).toList();
  }

  Future<void> addFocusSession(FocusSession session) => _db
      .from('focus_sessions')
      .insert({...session.toJson(), 'user_id': _uid});

  Future<void> deleteFocusSession(String id) => _db
      .from('focus_sessions')
      .delete()
      .eq('id', id)
      .eq('user_id', _uid);

  // ── SEED DEFAULT DATA ─────────────────────────────────────────
  /// Called on first sign-up to populate default schedule blocks,
  /// calendar events, and habits.
  Future<void> _seedDefaultData(String uid) async {
    // Default habits
    final defaultHabits = [
      {'id': _uuid(), 'user_id': uid, 'name': 'Fajr on time', 'icon': '🕌', 'order': 0, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Quran (35 min)', 'icon': '📖', 'order': 1, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Morning Zekr', 'icon': '📿', 'order': 2, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Evening Zekr', 'icon': '🌙', 'order': 3, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Walk 30 min', 'icon': '🚶', 'order': 4, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'PMP study', 'icon': '📋', 'order': 5, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'CFI study', 'icon': '📚', 'order': 6, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
      {'id': _uuid(), 'user_id': uid, 'name': 'Kyberia outreach (5 emails)', 'icon': '⚗️', 'order': 7, 'streak': 0, 'longest_streak': 0, 'history': {}, 'is_archived': false},
    ];
    await _db.from('habits').insert(defaultHabits);

    // Default goals
    final defaultGoals = [
      {'id': _uuid(), 'user_id': uid, 'title': 'PMP Certified', 'target_date': '2026-06-30', 'priority': 'high', 'status': 'active', 'progress': 0, 'description': 'Study starts now. Exam by June 30.', 'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'First Kyberia Client', 'target_date': '2026-05-01', 'priority': 'high', 'status': 'active', 'progress': 10, 'description': 'Cold outreach + crawler pipeline', 'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Product #1 Live', 'target_date': '2026-04-10', 'priority': 'high', 'status': 'active', 'progress': 0, 'description': 'MVP by April 10 — no perfectionism', 'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Debt ≤ 100K EGP', 'target_date': '2026-09-15', 'priority': 'high', 'status': 'active', 'progress': 0, 'description': 'Salary + Kyberia revenue → debt first', 'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Memorize 10 Juz Quran', 'target_date': '2026-12-31', 'priority': 'high', 'status': 'active', 'progress': 0, 'description': '35 min/day = ~1 juz per 20 days', 'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Get Engaged', 'target_date': '2026-05-30', 'priority': 'high', 'status': 'active', 'progress': 95, 'description': 'May 30, 2026 إن شاء الله', 'milestones': [], 'linked_event_ids': []},
      {'id': _uuid(), 'user_id': uid, 'title': 'Wedding', 'target_date': '2027-03-01', 'priority': 'high', 'status': 'active', 'progress': 0, 'description': 'March 2027 إن شاء الله 🤍', 'milestones': [], 'linked_event_ids': []},
    ];
    await _db.from('goals').insert(defaultGoals);

    // Seed default schedule blocks (normal mode)
    await _seedScheduleBlocks(uid);

    // Seed default calendar events (milestones + Islamic dates)
    await _seedDefaultCalendarEvents(uid);
  }

  Future<void> _seedScheduleBlocks(String uid) async {
    final normalBlocks = [
      {'schedule_mode': 'normal', 'time': '04:25', 'label': 'Qiyam al-Layl', 'category_key': 'deen', 'duration': '30m', 'note': 'Start 2 rakaat. Build gradually.', 'order': 0},
      {'schedule_mode': 'normal', 'time': '04:55', 'label': 'Fajr + Morning Zekr', 'category_key': 'deen', 'duration': '15m', 'note': null, 'order': 1},
      {'schedule_mode': 'normal', 'time': '05:10', 'label': 'Quran — recitation & memorization', 'category_key': 'deen', 'duration': '35m', 'note': '10 juz by Dec 31 إن شاء الله', 'order': 2},
      {'schedule_mode': 'normal', 'time': '05:45', 'label': 'Get ready', 'category_key': 'rest', 'duration': '5m', 'note': 'No breakfast. Wash, dress, bag.', 'order': 3},
      {'schedule_mode': 'normal', 'time': '05:50', 'label': 'PMP — quick morning review', 'category_key': 'pmp', 'duration': '10m', 'note': null, 'order': 4},
      {'schedule_mode': 'normal', 'time': '06:00', 'label': 'Commute to site', 'category_key': 'com', 'duration': '1hr', 'note': '🎧 PMP audio or Quran', 'order': 5},
      {'schedule_mode': 'normal', 'time': '07:00', 'label': 'Site work', 'category_key': 'work', 'duration': '5hrs', 'note': null, 'order': 6},
      {'schedule_mode': 'normal', 'time': '12:00', 'label': 'Lunch break — PMP reading', 'category_key': 'pmp', 'duration': '1hr', 'note': 'Main PMP slot. No food — full focus.', 'order': 7},
      {'schedule_mode': 'normal', 'time': '13:00', 'label': 'Site work continues', 'category_key': 'work', 'duration': '4hrs', 'note': null, 'order': 8},
      {'schedule_mode': 'normal', 'time': '17:00', 'label': 'Commute home', 'category_key': 'com', 'duration': '1hr', 'note': '🎧 CFI audio or Evening Zekr', 'order': 9},
      {'schedule_mode': 'normal', 'time': '18:00', 'label': 'Arrive + settle', 'category_key': 'rest', 'duration': '10m', 'note': null, 'order': 10},
      {'schedule_mode': 'normal', 'time': '18:10', 'label': 'Maghrib + Evening Zekr', 'category_key': 'deen', 'duration': '20m', 'note': null, 'order': 11},
      {'schedule_mode': 'normal', 'time': '18:30', 'label': 'Dinner + CFI Study', 'category_key': 'study', 'duration': '90m', 'note': 'Eat while studying.', 'order': 12},
      {'schedule_mode': 'normal', 'time': '20:00', 'label': 'Walk', 'category_key': 'health', 'duration': '30m', 'note': null, 'order': 13},
      {'schedule_mode': 'normal', 'time': '20:30', 'label': 'Kyberia — outreach + build', 'category_key': 'kyb', 'duration': '40m', 'note': null, 'order': 14},
      {'schedule_mode': 'normal', 'time': '21:10', 'label': 'Isha', 'category_key': 'deen', 'duration': '15m', 'note': null, 'order': 15},
      {'schedule_mode': 'normal', 'time': '21:25', 'label': 'Wind down', 'category_key': 'rest', 'duration': '60m', 'note': null, 'order': 16},
      {'schedule_mode': 'normal', 'time': '22:25', 'label': 'Sleep', 'category_key': 'rest', 'duration': null, 'note': '→ 04:25 = 6hrs exactly', 'order': 17},
    ];

    final rows = normalBlocks.map((b) => {...b, 'id': _uuid(), 'user_id': uid, 'notify_on_start': true, 'notify_on_end': false}).toList();
    await _db.from('schedule_blocks').insert(rows);
  }

  String _uuid() => _uuidGen.v4();

  // ── CASH ON HAND ───────────────────────────────────────────
  Future<double> getCashOnHand() async {
    final row = await _db.from('profiles').select('cash_on_hand').eq('id', _uid).maybeSingle();
    return (row?['cash_on_hand'] as num?)?.toDouble() ?? 0;
  }

  Future<void> setCashOnHand(double amount) async {
    await _db.from('profiles').update({'cash_on_hand': amount}).eq('id', _uid);
  }

  // ── SEED CALENDAR EVENTS ───────────────────────────────────
  Future<void> _seedDefaultCalendarEvents(String uid) async {
    final events = <Map<String, dynamic>>[
      {'id': _uuid(), 'user_id': uid, 'title': 'Engagement', 'date': '2026-05-30', 'type_key': 'milestone', 'is_done': false, 'notes': 'إن شاء الله 🤍'},
      {'id': _uuid(), 'user_id': uid, 'title': 'Wedding', 'date': '2027-03-01', 'type_key': 'milestone', 'is_done': false, 'notes': 'March 2027 إن شاء الله'},
      {'id': _uuid(), 'user_id': uid, 'title': 'PMP Exam Deadline', 'date': '2026-06-30', 'type_key': 'milestone', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Product #1 MVP', 'date': '2026-04-10', 'type_key': 'milestone', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'First Kyberia Client', 'date': '2026-05-01', 'type_key': 'milestone', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Ramadan Start', 'date': '2026-02-18', 'type_key': 'islamic', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Eid Al-Fitr', 'date': '2026-03-20', 'type_key': 'islamic', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Eid Al-Adha', 'date': '2026-05-27', 'type_key': 'islamic', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Islamic New Year', 'date': '2026-06-17', 'type_key': 'islamic', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Mawlid Al-Nabi', 'date': '2026-08-26', 'type_key': 'islamic', 'is_done': false},
      {'id': _uuid(), 'user_id': uid, 'title': 'Debt ≤ 100K Target', 'date': '2026-09-15', 'type_key': 'milestone', 'is_done': false},
    ];
    await _db.from('calendar_events').insert(events);
  }

  // ── FASTING ────────────────────────────────────────────────────
  Future<List<FastRecord>> getFastingRecords() async {
    final res = await _db
        .from('fasting_records')
        .select()
        .eq('user_id', _uid)
        .order('start_time', ascending: false);
    return res.map((j) => FastRecord.fromJson(j)).toList();
  }

  Future<FastRecord> startFastRecord({
    required DateTime startTime,
    required int goalHours,
  }) async {
    final row = await _db.from('fasting_records').insert({
      'user_id': _uid,
      'start_time': startTime.toIso8601String(),
      'goal_hours': goalHours,
    }).select().single();
    return FastRecord.fromJson(row);
  }

  Future<void> updateFastRecord(
    String id, {
    DateTime? endTime,
    int? goalHours,
  }) async {
    final data = <String, dynamic>{};
    if (endTime != null) data['end_time'] = endTime.toIso8601String();
    if (goalHours != null) data['goal_hours'] = goalHours;
    if (data.isEmpty) return;
    await _db
        .from('fasting_records')
        .update(data)
        .eq('id', id)
        .eq('user_id', _uid);
  }

  // ── IDEAS ──────────────────────────────────────────────────────
  Future<List<Idea>> getIdeas() async {
    final res = await _db
        .from('ideas')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return res.map((j) => Idea.fromJson(j)).toList();
  }

  Future<Idea> upsertIdea(Idea idea) async {
    final row = await _db
        .from('ideas')
        .upsert({...idea.toJson(), 'user_id': _uid})
        .select()
        .single();
    return Idea.fromJson(row);
  }

  Future<void> deleteIdea(String id) =>
      _db.from('ideas').delete().eq('id', id).eq('user_id', _uid);
}
