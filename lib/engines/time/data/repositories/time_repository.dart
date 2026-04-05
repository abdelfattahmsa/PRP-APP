import '../../../../services/supabase_service.dart';
import '../models/time_models.dart';

/// Repository for Time Engine (Schedule + Calendar).
class TimeRepository {
  TimeRepository._();
  static final instance = TimeRepository._();

  final _service = SupabaseService.instance;

  // ── Schedule ──
  Future<List<ScheduleBlock>> getScheduleBlocks(String mode) =>
      _service.getScheduleBlocks(mode);
  Future<void> upsertBlock(ScheduleBlock block) => _service.upsertBlock(block);
  Future<void> deleteBlock(String id) => _service.deleteBlock(id);
  Future<void> reorderBlocks(List<ScheduleBlock> blocks) =>
      _service.reorderBlocks(blocks);

  // ── Calendar ──
  Future<List<CalendarEvent>> getCalendarEvents({DateTime? from, DateTime? to}) =>
      _service.getCalendarEvents(from: from, to: to);
  Future<CalendarEvent> upsertEvent(CalendarEvent event) =>
      _service.upsertEvent(event);
  Future<void> deleteEvent(String id) => _service.deleteEvent(id);
  Future<void> markEventDone(String id, bool done) =>
      _service.markEventDone(id, done);
}
