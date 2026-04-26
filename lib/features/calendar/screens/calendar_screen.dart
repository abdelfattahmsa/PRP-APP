import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_text_field.dart';

const _uuid = Uuid();

// ── CALENDAR SCREEN ──────────────────────────────────────────
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final d = _selected ?? DateTime.now();
              context.push('${Routes.calendar}/event?date=${d.toIso8601String().split('T').first}');
            },
          ),
        ],
      ),
      body: calAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (events) {
          final notifier = ref.read(calendarProvider.notifier);
          return Column(children: [
            // Calendar widget
            TableCalendar<CalendarEvent>(
              firstDay: DateTime(2026, 1, 1),
              lastDay: DateTime(2027, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              calendarFormat: _format,
              startingDayOfWeek: StartingDayOfWeek.saturday,
              eventLoader: (day) => notifier.eventsForDay(day),
              onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
              onFormatChanged: (f) => setState(() => _format = f),
              onPageChanged: (foc) => setState(() => _focused = foc),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Roboto', fontSize: 12),
                weekendTextStyle: const TextStyle(color: AppColors.gold, fontFamily: 'Roboto', fontSize: 12),
                selectedDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: AppColors.bg, fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700),
                todayDecoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
                todayTextStyle: const TextStyle(color: AppColors.gold, fontFamily: 'Roboto', fontSize: 12),
                markerDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                markersMaxCount: 4,
                cellMargin: const EdgeInsets.all(2),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.all(color: AppColors.border),
                ),
                formatButtonTextStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Roboto'),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                titleTextStyle: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppColors.textSecondary),
                weekendStyle: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppColors.gold),
              ),
            ),
            const Divider(height: 1),
            // Events for selected day
            Expanded(
              child: _SelectedDayEvents(
                day: _selected ?? DateTime.now(),
                events: notifier.eventsForDay(_selected ?? DateTime.now()),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _SelectedDayEvents extends ConsumerWidget {
  const _SelectedDayEvents({required this.day, required this.events});
  final DateTime day;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_available, size: 36, color: AppColors.textMuted),
          const Gap(8),
          const Text('No events this day', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Gap(12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Event'),
            onPressed: () => context.push('${Routes.calendar}/event?date=${day.toIso8601String().split('T').first}'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: events.length,
      itemBuilder: (ctx, i) => _EventTile(event: events[i], index: i),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event, required this.index});
  final CalendarEvent event;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeInfo = eventTypeInfoMap[event.typeKey];
    final color = AppColors.categoryColor(event.typeKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Dismissible(
        key: ValueKey('ev_${event.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        confirmDismiss: (_) async {
          if (event.isDefault) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default events cannot be deleted')));
            return false;
          }
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete event?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          );
        },
        onDismissed: (_) => ref.read(calendarProvider.notifier).deleteEvent(event.id),
        child: Container(
          decoration: BoxDecoration(
            color: event.isDone ? AppColors.card.withValues(alpha: 0.5) : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: event.isDone ? AppColors.done.withValues(alpha: 0.3) : color.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push('${Routes.calendar}/event?id=${event.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                // Type dot
                Container(
                  width: 4, height: 40,
                  decoration: BoxDecoration(
                    color: event.isDone ? AppColors.done : color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(typeInfo?.label ?? event.typeKey, style: TextStyle(fontFamily: 'Roboto', fontSize: 8, color: color, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ),
                    const Gap(6),
                    if (event.isDone) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.done.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('DONE', style: TextStyle(fontFamily: 'Roboto', fontSize: 8, color: AppColors.done)),
                    ),
                  ]),
                  const Gap(4),
                  Text(
                    event.title,
                    style: TextStyle(fontSize: 13.5, color: event.isDone ? AppColors.textSecondary : AppColors.textPrimary, decoration: event.isDone ? TextDecoration.lineThrough : null),
                  ),
                  if (event.notes != null && event.notes!.isNotEmpty) ...[
                    const Gap(3),
                    Text(event.notes!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                  if (event.linkUrl != null && event.linkUrl!.isNotEmpty) ...[
                    const Gap(4),
                    Row(children: [
                      const Icon(Icons.link, size: 11, color: AppColors.learn),
                      const Gap(3),
                      Text(event.linkUrl!.length > 40 ? '${event.linkUrl!.substring(0, 40)}...' : event.linkUrl!, style: const TextStyle(fontSize: 10, color: AppColors.learn)),
                    ]),
                  ],
                ])),
                // Actions
                Column(children: [
                  IconButton(
                    icon: Icon(event.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: event.isDone ? AppColors.deen : AppColors.textSecondary, size: 20),
                    onPressed: () => ref.read(calendarProvider.notifier).markDone(event.id, !event.isDone),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const Gap(6),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                ]),
              ]),
            ),
          ),
        ),
      ).animate(delay: (index * 30).ms).fadeIn(duration: 200.ms).slideY(begin: 0.05),
    );
  }
}

// ── EVENT DETAIL / EDIT SCREEN ───────────────────────────────
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, this.eventId, this.initialDate});
  final String? eventId;
  final DateTime? initialDate;
  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailState();
}

class _EventDetailState extends ConsumerState<EventDetailScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _link  = TextEditingController();
  String _type = 'personal';
  DateTime _date = DateTime.now();
  bool _saving = false;
  CalendarEvent? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _date = widget.initialDate!;
    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final events = ref.read(calendarProvider).value;
        if (events == null) return;
        final ev = events.firstWhere((e) => e.id == widget.eventId, orElse: () => events.first);
        _existing = ev;
        _title.text = ev.title;
        _notes.text = ev.notes ?? '';
        _link.text  = ev.linkUrl ?? '';
        setState(() { _type = ev.typeKey; _date = ev.date; });
      });
    }
  }

  @override
  void dispose() { _title.dispose(); _notes.dispose(); _link.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_title.text.isEmpty) return;
    setState(() => _saving = true);
    final event = CalendarEvent(
      id: _existing?.id ?? _uuid.v4(),
      date: _date,
      title: _title.text.trim(),
      typeKey: _type,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      linkUrl: _link.text.trim().isEmpty ? null : _link.text.trim(),
      isDone: _existing?.isDone ?? false,
    );
    if (_existing != null) {
      await ref.read(calendarProvider.notifier).updateEvent(event);
    } else {
      await ref.read(calendarProvider.notifier).addEvent(event);
    }
    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.eventId == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Event' : 'Edit Event'),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)))
              : TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.gold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppTextField(controller: _title, label: 'Event Title', hint: 'What is this event?', autofocus: isNew),
          const Gap(14),
          // Date picker
          const Text('Date', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'Roboto', letterSpacing: 0.5)),
          const Gap(6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                const Gap(10),
                Text('${_date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_date.month - 1]} ${_date.year}',
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.textPrimary)),
                const Spacer(),
                const Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary),
              ]),
            ),
          ),
          const Gap(14),
          // Event type
          const Text('Type', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'Roboto', letterSpacing: 0.5)),
          const Gap(6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: AppConstants.eventTypeKeys.map((k) {
              final info = eventTypeInfoMap[k];
              final color = AppColors.categoryColor(k);
              final sel = _type == k;
              return GestureDetector(
                onTap: () => setState(() => _type = k),
                child: AnimatedContainer(
                  duration: 120.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: 0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: sel ? color.withValues(alpha: 0.5) : AppColors.border),
                  ),
                  child: Text('${info?.emoji ?? ''} ${info?.label ?? k}', style: TextStyle(fontFamily: 'Roboto', fontSize: 10.5, color: sel ? color : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const Gap(14),
          AppTextField(controller: _notes, label: 'Notes (optional)', hint: 'Any details or context...', maxLines: 3),
          const Gap(14),
          AppTextField(controller: _link, label: 'Link / Attachment URL', hint: 'https://...', keyboardType: TextInputType.url),
          if (!isNew && _existing != null && !_existing!.isDefault) ...[
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('Delete Event', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                onPressed: () async {
                  await ref.read(calendarProvider.notifier).deleteEvent(_existing!.id);
                  if (context.mounted) context.pop();
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }
}