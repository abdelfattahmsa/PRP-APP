import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/checkin_models.dart';

const _uuid = Uuid();

class CheckinRepository {
  CheckinRepository._();
  static final instance = CheckinRepository._();

  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<DailyCheckin?> getTodayCheckin(String date) async {
    final res = await _db
        .from('daily_checkins')
        .select()
        .eq('user_id', _uid)
        .eq('date', date)
        .maybeSingle();
    return res != null ? DailyCheckin.fromJson(res) : null;
  }

  Future<DailyCheckin> upsertCheckin(DailyCheckin checkin) async {
    final payload = {
      'user_id': _uid,
      'date': checkin.date,
      if (checkin.morningEnergy != null)
        'morning_energy': checkin.morningEnergy,
      if (checkin.topPriority != null)
        'top_priority': checkin.topPriority,
      if (checkin.eveningMood != null)
        'evening_mood': checkin.eveningMood,
      if (checkin.accomplishment != null)
        'accomplishment': checkin.accomplishment,
    };

    final res = await _db
        .from('daily_checkins')
        .upsert(payload, onConflict: 'user_id,date')
        .select()
        .single();
    return DailyCheckin.fromJson(res);
  }

  /// Returns last [days] checkins ordered newest first.
  Future<List<DailyCheckin>> getRecentCheckins(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    final res = await _db
        .from('daily_checkins')
        .select()
        .eq('user_id', _uid)
        .gte('date', cutoffStr)
        .order('date', ascending: false);
    return res.map(DailyCheckin.fromJson).toList();
  }

  String _newId() => _uuid.v4();
  String get newId => _newId();
}
