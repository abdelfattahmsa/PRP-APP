import '../../../../services/supabase_service.dart';
import '../models/energy_models.dart';

/// Repository for Energy Engine (Focus sessions).
class EnergyRepository {
  EnergyRepository._();
  static final instance = EnergyRepository._();

  final _service = SupabaseService.instance;

  Future<List<FocusSession>> getFocusSessions({int limit = 100}) =>
      _service.getFocusSessions(limit: limit);
  Future<void> addFocusSession(FocusSession session) =>
      _service.addFocusSession(session);
  Future<void> deleteFocusSession(String id) =>
      _service.deleteFocusSession(id);
}
