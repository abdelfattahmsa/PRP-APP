import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/religion_models.dart';

const _uuid = Uuid();

class ReligionRepository {
  ReligionRepository._();
  static final instance = ReligionRepository._();

  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  // ── SALAH ─────────────────────────────────────────────────

  Future<SalahRecord?> getSalahRecord(String date) async {
    final res = await _db
        .from('salah_records')
        .select()
        .eq('user_id', _uid)
        .eq('date', date)
        .maybeSingle();
    return res != null ? SalahRecord.fromJson(res) : null;
  }

  Future<SalahRecord> upsertSalahRecord(SalahRecord record) async {
    final payload = record.toJson();
    if (record.id.isEmpty) {
      payload['id'] = _uuid.v4();
      payload.remove('id'); // let DB generate it
    }
    final res = await _db
        .from('salah_records')
        .upsert({
          'user_id': _uid,
          'date': record.date,
          'prayers': record.prayers,
        }, onConflict: 'user_id,date')
        .select()
        .single();
    return SalahRecord.fromJson(res);
  }

  /// Returns the last [days] salah records, newest first.
  Future<List<SalahRecord>> getSalahHistory(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = '${cutoff.year}-'
        '${cutoff.month.toString().padLeft(2, '0')}-'
        '${cutoff.day.toString().padLeft(2, '0')}';
    final res = await _db
        .from('salah_records')
        .select()
        .eq('user_id', _uid)
        .gte('date', cutoffStr)
        .order('date', ascending: false);
    return res.map(SalahRecord.fromJson).toList();
  }

  // ── QURAN ────────────────────────────────────────────────

  Future<List<QuranSession>> getQuranSessions({int limit = 50}) async {
    final res = await _db
        .from('quran_sessions')
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .limit(limit);
    return res.map(QuranSession.fromJson).toList();
  }

  Future<QuranSession> addQuranSession(QuranSession session) async {
    final res = await _db
        .from('quran_sessions')
        .insert({...session.toJson(), 'user_id': _uid})
        .select()
        .single();
    return QuranSession.fromJson(res);
  }

  Future<void> deleteQuranSession(String id) async {
    await _db
        .from('quran_sessions')
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  /// Total minutes read/memorised in the last [days] days.
  Future<int> getQuranMinutesThisWeek() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final cutoffStr = '${cutoff.year}-'
        '${cutoff.month.toString().padLeft(2, '0')}-'
        '${cutoff.day.toString().padLeft(2, '0')}';
    final res = await _db
        .from('quran_sessions')
        .select('minutes')
        .eq('user_id', _uid)
        .gte('date', cutoffStr);
    return (res as List).fold<int>(0, (sum, r) => sum + (r['minutes'] as int? ?? 0));
  }
}
