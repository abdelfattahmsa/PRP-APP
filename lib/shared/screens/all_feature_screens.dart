// ══════════════════════════════════════════════════════════════
// ALL MAIN FEATURE SCREENS
// Each screen is a full Consumer widget with real functionality.
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../calendar/providers/all_providers.dart';
import '../../schedule/providers/schedule_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _egpFmt = NumberFormat('#,###', 'en_US');
String _fmt(double v) => 'EGP ${_egpFmt.format(v)}';

// ══ OVERVIEW ══════════════════════════════════════════════════
class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});
  @override
  ConsumerState<OverviewScreen> createState() => _OverviewState();
}

class _OverviewState extends ConsumerState<OverviewScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedScheduleModeProvider);
    final curBlock = ref.watch(currentBlockProvider);
    final nextBlock = ref.watch(nextBlockProvider);
    final habits = ref.watch(habitsProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final finance = ref.watch(financeProvider).valueOrNull;
    final sessions = ref.watch(focusSessionsProvider).valueOrNull ?? [];
    final calEvents = ref.watch(calendarEventsProvider).valueOrNull ?? [];

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final doneHabits = habits.where((h) => h.isDoneToday).length;
    final todayMins = sessions.where((s) => s.completed && DateFormat('yyyy-MM-dd').format(s.date) == todayStr).fold(0, (a, s) => a + s.actualMinutes);
    final activeGoals = goals.where((g) => g.status == 'active').length;
    final upcomingEvents = calEvents.where((e) => !e.isDone && e.date.isAfter(today.subtract(const Duration(days: 1)))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        // Clock + current block
        _buildClockCard(context, curBlock, nextBlock, mode),
        const Gap(12),
        // Stats row
        Row(children: [
          Expanded(child: _StatTile(label: 'Habits', value: '$doneHabits/${habits.length}', color: doneHabits == habits.length ? AppColors.deen : AppColors.gold)),
          const Gap(8),
          Expanded(child: _StatTile(label: 'Focus', value: '${todayMins}m', color: AppColors.pmp)),
          const Gap(8),
          Expanded(child: _StatTile(label: 'Goals', value: '$activeGoals active', color: AppColors.kyberia)),
          const Gap(8),
          Expanded(child: _StatTile(label: 'Debt', value: finance != null ? _fmt(finance.totalDebt) : '—', color: AppColors.error, small: true)),
        ]),
        const Gap(12),
        // Finance snapshot
        if (finance != null) _buildFinanceCard(context, finance),
        const Gap(12),
        // Upcoming events
        _buildEventsCard(context, upcomingEvents),
        const Gap(12),
        // Goals snapshot
        _buildGoalsCard(context, goals.where((g) => g.status == 'active').take(4).toList()),
        const Gap(12),
        // Milestones strip
        _buildMilestonesCard(context),
      ]),
    );
  }

  Widget _buildClockCard(BuildContext context, ScheduleBlock? cur, ScheduleBlock? nxt, String mode) {
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_now);
    final color = cur != null ? AppColors.categoryColor(cur.categoryKey) : AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF0F0B1C), const Color(0xFF0A0914)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(timeStr, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
        Text(dateStr, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary)),
        if (cur != null) ...[
          const Gap(14),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.25))),
            child: Row(children: [
              Container(width: 3, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const Gap(10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NOW · $mode'.toUpperCase(), style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: color, letterSpacing: 1)),
                Text(cur.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (cur.note != null) Text(cur.note!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ])),
              if (cur.duration != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.35))),
                child: Text(cur.duration!, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: color))),
            ])),
          if (nxt != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Next: ${nxt.time} · ${nxt.label}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary))),
        ],
      ]),
    );
  }

  Widget _buildFinanceCard(BuildContext context, FinanceState f) => _card(
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Finance', style: Theme.of(context).textTheme.titleLarge),
        Text(_fmt(f.totalDebt), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
      ]),
      const Gap(8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (f.totalDebt / 200000).clamp(0,1), backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.error), minHeight: 5)),
      const Gap(6),
      Row(children: [
        Text('Target ≤ 100K by Sep', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        Text('${_fmt((f.totalDebt - 100000).clamp(0, double.infinity))} to go', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.warning)),
      ]),
      const Gap(10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _mini(context, 'CC Debt', _fmt(f.totalCC), AppColors.error),
        _mini(context, 'Savings', _fmt(f.totalSavings), AppColors.deen),
        _mini(context, 'Current', _fmt(f.totalCurrent), AppColors.gold),
      ]),
    ]),
  );

  Widget _buildEventsCard(BuildContext context, List<CalendarEvent> events) => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upcoming Events', style: Theme.of(context).textTheme.titleLarge),
      const Gap(10),
      if (events.isEmpty) Text('No upcoming events', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
      ...events.take(4).map((e) {
        final tc = AppColors.categoryColor(e.typeKey);
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          SizedBox(width: 50, child: Text(DateFormat('MMM d').format(e.date), style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: tc, fontWeight: FontWeight.w600))),
          Container(width: 5, height: 5, decoration: BoxDecoration(color: tc, shape: BoxShape.circle, boxShadow: [BoxShadow(color: tc.withOpacity(0.5), blurRadius: 4)])),
          const Gap(8),
          Expanded(child: Text(e.title, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
        ]));
      }),
    ]),
  );

  Widget _buildGoalsCard(BuildContext context, List<Goal> goals) => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Active Goals', style: Theme.of(context).textTheme.titleLarge),
      const Gap(10),
      ...goals.map((g) {
        final pc = {'high': AppColors.error, 'medium': AppColors.gold, 'low': AppColors.deen}[g.priority] ?? AppColors.gold;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(g.title, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
            Text('${g.progress}%', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: pc, fontWeight: FontWeight.w600)),
          ]),
          const Gap(3),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: g.progress / 100, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(pc), minHeight: 4)),
        ]));
      }),
    ]),
  );

  Widget _buildMilestonesCard(BuildContext context) {
    final milestones = [
      ('🚀 Product #1', 'Apr 10', AppColors.error),
      ('💼 1st Client', 'May 1', AppColors.kyberia),
      ('💍 Engaged', 'May 30', AppColors.personal),
      ('📋 PMP', '≤Jun 30', AppColors.fasting),
      ('📉 ≤100K', 'Sep', AppColors.commute),
      ('📖 10 Juz', 'Dec 31', AppColors.quran),
      ('💒 Wedding', "Mar '27", AppColors.personal),
    ];
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('2026 Milestones', style: Theme.of(context).textTheme.titleLarge),
        const Gap(10),
        Wrap(spacing: 8, runSpacing: 8, children: milestones.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(m.$1, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: m.$3, fontWeight: FontWeight.w600)),
            Text(m.$2, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
          ]),
        )).toList()),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: child);
  Widget _mini(BuildContext context, String label, String value, Color color) => Column(children: [
    Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
    const Gap(3),
    Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color, this.small = false});
  final String label;
  final String value;
  final Color color;
  final bool small;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
      const Gap(4),
      Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: small ? 11 : 14, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
    ]));
}

// ══ CALENDAR ══════════════════════════════════════════════════
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final notifier = ref.read(calendarEventsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _addEvent(context, _selected ?? DateTime.now())),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e')),
        data: (allEvents) {
          final selEvents = _selected == null ? [] : allEvents.where((e) => isSameDay(e.date, _selected)).toList();
          return Column(children: [
            TableCalendar<CalendarEvent>(
              firstDay: DateTime(2026, 1, 1),
              lastDay: DateTime(2027, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              eventLoader: (day) => allEvents.where((e) => isSameDay(e.date, day)).toList(),
              onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
              onPageChanged: (foc) => setState(() => _focused = foc),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textPrimary),
                weekendTextStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.gold),
                todayDecoration: BoxDecoration(color: AppColors.gold.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
                selectedDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700),
                selectedTextStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.bg, fontWeight: FontWeight.w700),
                outsideDaysVisible: false,
                markerDecoration: const BoxDecoration(color: AppColors.kyberia, shape: BoxShape.circle),
                markerSize: 5,
                markersMaxCount: 3,
                cellMargin: const EdgeInsets.all(3),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary),
                weekendStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.gold),
              ),
            ),
            const Divider(),
            // Selected day events
            Expanded(
              child: selEvents.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.event_available, color: AppColors.textSecondary, size: 36),
                      const Gap(8),
                      Text('No events', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      const Gap(12),
                      ElevatedButton.icon(
                        onPressed: () => _addEvent(context, _selected ?? DateTime.now()),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Event'),
                      ),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: selEvents.length + 1,
                      itemBuilder: (_, i) {
                        if (i == selEvents.length) return TextButton.icon(icon: const Icon(Icons.add, size: 14), label: const Text('Add event'), onPressed: () => _addEvent(context, _selected ?? DateTime.now()));
                        final ev = selEvents[i];
                        return _EventTile(
                          event: ev,
                          onDone: (done) => notifier.markDone(ev.id, done),
                          onEdit: () => _editEvent(context, ev),
                          onDelete: () => notifier.deleteEvent(ev.id),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideX(begin: -0.05);
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }

  void _addEvent(BuildContext ctx, DateTime date) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => _EventForm(
      initialDate: date,
      onSave: (ev) => ref.read(calendarEventsProvider.notifier).addEvent(ev),
    ));
  }

  void _editEvent(BuildContext ctx, CalendarEvent ev) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => _EventForm(
      existing: ev,
      initialDate: ev.date,
      onSave: (updated) => ref.read(calendarEventsProvider.notifier).updateEvent(updated),
    ));
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onDone, required this.onEdit, required this.onDelete});
  final CalendarEvent event;
  final void Function(bool) onDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final tc = AppColors.categoryColor(event.typeKey);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tc.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: event.isDone ? AppColors.done.withOpacity(0.3) : tc.withOpacity(0.3))),
      child: Row(children: [
        Container(width: 3, decoration: BoxDecoration(color: event.isDone ? AppColors.done : tc, borderRadius: BorderRadius.circular(2)), height: 40),
        const Gap(10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eventTypeInfoMap[event.typeKey]?.label.toUpperCase() ?? 'EVENT', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8.5, color: tc, letterSpacing: 0.8)),
          Text(event.title, style: TextStyle(fontSize: 13, color: event.isDone ? AppColors.textSecondary : AppColors.textPrimary, decoration: event.isDone ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w500)),
          if (event.notes != null && event.notes!.isNotEmpty) Text(event.notes!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          if (event.linkUrl != null) Text('🔗 ${event.linkUrl}', style: const TextStyle(fontSize: 9.5, color: AppColors.pmp), overflow: TextOverflow.ellipsis),
        ])),
        IconButton(icon: Icon(event.isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: event.isDone ? AppColors.deen : AppColors.textSecondary), onPressed: () => onDone(!event.isDone)),
        if (!event.isDefault) PopupMenuButton<String>(
          iconSize: 16, color: AppColors.card,
          onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ]),
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({required this.initialDate, this.existing, required this.onSave});
  final DateTime initialDate;
  final CalendarEvent? existing;
  final void Function(CalendarEvent) onSave;
  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late final _link = TextEditingController(text: widget.existing?.linkUrl ?? '');
  late DateTime _date = widget.initialDate;
  late String _type = widget.existing?.typeKey ?? 'personal';

  @override
  void dispose() { _title.dispose(); _notes.dispose(); _link.dispose(); super.dispose(); }

  void _submit() {
    if (_title.text.isEmpty) return;
    widget.onSave(CalendarEvent(id: widget.existing?.id ?? _uuid.v4(), date: _date, title: _title.text.trim(), typeKey: _type, notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(), linkUrl: _link.text.trim().isEmpty ? null : _link.text.trim()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.existing == null ? 'New Event' : 'Edit Event', style: Theme.of(context).textTheme.headlineSmall),
      const Gap(16),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2026), lastDate: DateTime(2027,12,31));
          if (d != null) setState(() => _date = d);
        }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(children: [const Icon(Icons.calendar_today, size: 14, color: AppColors.gold), const Gap(6), Text(DateFormat('MMM d, yyyy').format(_date), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary))])
        ))),
        const Gap(10),
        Expanded(child: DropdownButtonFormField<String>(
          initialValue: _type, dropdownColor: AppColors.card,
          decoration: const InputDecoration(labelText: 'Type'),
          items: AppConstants.eventTypeKeys.map((k) => DropdownMenuItem(value: k, child: Text(eventTypeInfoMap[k]?.label ?? k, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _type = v ?? _type),
        )),
      ]),
      const Gap(12),
      AppTextField(controller: _title, label: 'Title', hint: 'Event title...', autofocus: true),
      const Gap(10),
      AppTextField(controller: _notes, label: 'Notes (optional)', maxLines: 2),
      const Gap(10),
      AppTextField(controller: _link, label: 'Link/URL (optional)', hint: 'https://...'),
      const Gap(16),
      ElevatedButton(onPressed: _submit, child: Text(widget.existing == null ? 'Add Event' : 'Save Changes')),
    ])),
  );
}

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, this.eventId, this.initialDate});
  final String? eventId;
  final DateTime? initialDate;
  @override
  Widget build(BuildContext context) => const CalendarScreen();
}

// ══ FINANCE ═══════════════════════════════════════════════════
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finAsync = ref.watch(financeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: finAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e')),
        data: (fin) => _FinanceBody(fin: fin),
      ),
    );
  }
}

class _FinanceBody extends ConsumerStatefulWidget {
  const _FinanceBody({required this.fin});
  final FinanceState fin;
  @override
  ConsumerState<_FinanceBody> createState() => _FinanceBodyState();
}

class _FinanceBodyState extends ConsumerState<_FinanceBody> with SingleTickerProviderStateMixin {
  late final _tc = TabController(length: 4, vsync: this);

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fin = widget.fin;
    final n = ref.read(financeProvider.notifier);
    return Column(children: [
      // Summary
      Container(color: AppColors.surface, padding: const EdgeInsets.all(12), child: Column(children: [
        Row(children: [
          Expanded(child: _FCard('Total Debt', _fmt(fin.totalDebt), AppColors.error)),
          const Gap(8),
          Expanded(child: _FCard('CC Balance', _fmt(fin.totalCC), AppColors.error)),
          const Gap(8),
          Expanded(child: _FCard('Rem. Limit', _fmt(fin.remainingCreditLimit), AppColors.deen)),
        ]),
        const Gap(8),
        Row(children: [
          Expanded(child: _FCard('Savings', _fmt(fin.totalSavings), AppColors.gold)),
          const Gap(8),
          Expanded(child: _FCard('Current', _fmt(fin.totalCurrent), AppColors.pmp)),
          const Gap(8),
          Expanded(child: _FCard('Ext. Debt', _fmt(fin.totalExternalDebt), AppColors.error)),
        ]),
        const Gap(8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (fin.totalDebt / 200000).clamp(0, 1), backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.error), minHeight: 6)),
        const Gap(4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Debt target ≤ 100K by Sep', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
          Text(_fmt((fin.totalDebt - 100000).clamp(0, double.infinity)) + ' to go', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.warning)),
        ]),
      ])),
      // Tabs
      TabBar(controller: _tc, tabs: const [Tab(text: 'Banks'), Tab(text: 'Debts'), Tab(text: 'Invest'), Tab(text: 'Tx')], labelColor: AppColors.gold, unselectedLabelColor: AppColors.textSecondary, indicatorColor: AppColors.gold, labelStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, fontWeight: FontWeight.w600)),
      Expanded(child: TabBarView(controller: _tc, children: [
        _BanksTab(banks: fin.banks, onUpdate: n.updateBank, onAdd: n.addBank),
        _DebtsTab(debts: fin.debts, onAdd: (d) => n.addDebt(d), onDelete: n.deleteDebt),
        _InvestmentsTab(investments: fin.investments, onAdd: (i) => n.addInvestment(i), onDelete: n.deleteInvestment),
        _TransactionsTab(transactions: fin.transactions, banks: fin.banks, onAdd: (t) => n.addTransaction(t), onDelete: n.deleteTransaction),
      ])),
    ]);
  }
}

class _FCard extends StatelessWidget {
  const _FCard(this.label, this.value, this.color);
  final String label, value; final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
      const Gap(3),
      Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
    ]));
}

class _BanksTab extends StatelessWidget {
  const _BanksTab({required this.banks, required this.onUpdate, required this.onAdd});
  final List<BankAccount> banks; final void Function(BankAccount) onUpdate; final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    ...banks.map((b) => _BankCard(bank: b, onUpdate: onUpdate)),
    const Gap(10),
    OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 16), label: const Text('Add Bank')),
  ]);
}

class _BankCard extends StatefulWidget {
  const _BankCard({required this.bank, required this.onUpdate});
  final BankAccount bank; final void Function(BankAccount) onUpdate;
  @override
  State<_BankCard> createState() => _BankCardState();
}

class _BankCardState extends State<_BankCard> {
  late final _name = TextEditingController(text: widget.bank.name);
  late final _cc = TextEditingController(text: widget.bank.creditCardBalance.toString());
  late final _limit = TextEditingController(text: widget.bank.creditCardLimit.toString());
  late final _sav = TextEditingController(text: widget.bank.savingsBalance.toString());
  late final _cur = TextEditingController(text: widget.bank.currentBalance.toString());

  void _save() => widget.onUpdate(BankAccount(id: widget.bank.id, name: _name.text, creditCardBalance: double.tryParse(_cc.text) ?? 0, creditCardLimit: double.tryParse(_limit.text) ?? 0, savingsBalance: double.tryParse(_sav.text) ?? 0, currentBalance: double.tryParse(_cur.text) ?? 0, order: widget.bank.order));

  @override
  void dispose() { _name.dispose(); _cc.dispose(); _limit.dispose(); _sav.dispose(); _cur.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      TextField(controller: _name, onEditingComplete: _save, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)),
      const Gap(10),
      Row(children: [
        Expanded(child: _numField('CC Balance', _cc, AppColors.error, _save)),
        const Gap(8),
        Expanded(child: _numField('CC Limit', _limit, AppColors.textSecondary, _save)),
        const Gap(8),
        Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Remaining', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
            const Gap(2),
            Text(_fmt(widget.bank.remainingCreditLimit), style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: widget.bank.isOverLimit ? AppColors.error : AppColors.deen, fontWeight: FontWeight.w600)),
          ])))],
      ),
      const Gap(8),
      Row(children: [
        Expanded(child: _numField('Savings', _sav, AppColors.deen, _save)),
        const Gap(8),
        Expanded(child: _numField('Current', _cur, AppColors.gold, _save)),
      ]),
    ]));

  Widget _numField(String label, TextEditingController ctrl, Color color, VoidCallback onDone) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
      const Gap(2),
      TextField(controller: ctrl, onEditingComplete: onDone, keyboardType: TextInputType.number, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: color, fontWeight: FontWeight.w600), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)),
    ]));
}

class _DebtsTab extends ConsumerStatefulWidget {
  const _DebtsTab({required this.debts, required this.onAdd, required this.onDelete});
  final List<ExternalDebt> debts; final void Function(ExternalDebt) onAdd; final void Function(String) onDelete;
  @override
  ConsumerState<_DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends ConsumerState<_DebtsTab> {
  final _src = TextEditingController(), _amt = TextEditingController(), _notes = TextEditingController();
  bool _showAdd = false;
  void _add() { if (_src.text.isEmpty || _amt.text.isEmpty) return; widget.onAdd(ExternalDebt(id: '', source: _src.text, amount: double.tryParse(_amt.text) ?? 0, notes: _notes.text.isEmpty ? null : _notes.text)); _src.clear(); _amt.clear(); _notes.clear(); setState(() => _showAdd = false); }
  @override
  void dispose() { _src.dispose(); _amt.dispose(); _notes.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    if (_showAdd) _card(Column(children: [AppTextField(controller: _src, label: 'Person / Source'), const Gap(8), AppTextField(controller: _amt, label: 'Amount (EGP)', keyboardType: TextInputType.number), const Gap(8), AppTextField(controller: _notes, label: 'Notes (optional)'), const Gap(10), Row(children: [Expanded(child: ElevatedButton(onPressed: _add, child: const Text('Add'))), const Gap(8), Expanded(child: OutlinedButton(onPressed: () => setState(() => _showAdd = false), child: const Text('Cancel')))])])),
    if (!_showAdd) OutlinedButton.icon(onPressed: () => setState(() => _showAdd = true), icon: const Icon(Icons.add, size: 16), label: const Text('Add Debt')),
    const Gap(10),
    if (widget.debts.isEmpty) const Center(child: Text('No external debts.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
    ...widget.debts.map((d) => _card(Row(children: [
      Container(width: 3, height: 40, color: d.isPaid ? AppColors.deen : AppColors.error, margin: const EdgeInsets.only(right: 10)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.source, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)), if (d.notes != null) Text(d.notes!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))])),
      Text(_fmt(d.amount), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), onPressed: () => widget.onDelete(d.id)),
    ]), margin: const EdgeInsets.only(bottom: 8))),
  ]);
  Widget _card(Widget child, {EdgeInsets? margin}) => Container(margin: margin ?? const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: child);
}

class _InvestmentsTab extends ConsumerStatefulWidget {
  const _InvestmentsTab({required this.investments, required this.onAdd, required this.onDelete});
  final List<Investment> investments; final void Function(Investment) onAdd; final void Function(String) onDelete;
  @override
  ConsumerState<_InvestmentsTab> createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends ConsumerState<_InvestmentsTab> {
  final _type = TextEditingController(), _amt = TextEditingController();
  String _unit = 'EGP'; bool _showAdd = false;
  void _add() { if (_type.text.isEmpty || _amt.text.isEmpty) return; widget.onAdd(Investment(id: '', type: _type.text, amount: double.tryParse(_amt.text) ?? 0, unit: _unit)); _type.clear(); _amt.clear(); setState(() => _showAdd = false); }
  @override
  void dispose() { _type.dispose(); _amt.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    if (_showAdd) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: Column(children: [
      AppTextField(controller: _type, label: 'Type', hint: 'Gold, Silver, Stocks...'),
      const Gap(8),
      Row(children: [
        Expanded(child: AppTextField(controller: _amt, label: 'Amount', keyboardType: TextInputType.number)),
        const Gap(8),
        Expanded(child: DropdownButtonFormField<String>(initialValue: _unit, dropdownColor: AppColors.card, decoration: const InputDecoration(labelText: 'Unit'),
          items: ['EGP','USD','g','oz','shares'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _unit = v!))),
      ]),
      const Gap(10),
      Row(children: [Expanded(child: ElevatedButton(onPressed: _add, child: const Text('Add'))), const Gap(8), Expanded(child: OutlinedButton(onPressed: () => setState(() => _showAdd = false), child: const Text('Cancel')))]),
    ])),
    if (!_showAdd) OutlinedButton.icon(onPressed: () => setState(() => _showAdd = true), icon: const Icon(Icons.add, size: 16), label: const Text('Add Investment')),
    const Gap(10),
    if (widget.investments.isEmpty) const Center(child: Text('No investments.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
    ...widget.investments.map((inv) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)), child: Row(children: [
      Expanded(child: Text(inv.type, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      Text('${_egpFmt.format(inv.amount)} ${inv.unit}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold)),
      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), onPressed: () => widget.onDelete(inv.id)),
    ]))),
  ]);
}

class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab({required this.transactions, required this.banks, required this.onAdd, required this.onDelete});
  final List<Transaction> transactions; final List<BankAccount> banks; final void Function(Transaction) onAdd; final void Function(String) onDelete;
  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  final _desc = TextEditingController(), _amt = TextEditingController(), _notes = TextEditingController();
  DateTime _date = DateTime.now(); String _cat = 'General'; String? _account; bool _showAdd = false;
  void _add() {
    if (_desc.text.isEmpty || _amt.text.isEmpty) return;
    widget.onAdd(Transaction(id: '', date: _date, description: _desc.text, amount: double.tryParse(_amt.text) ?? 0, category: _cat, accountName: _account ?? (widget.banks.isNotEmpty ? widget.banks.first.name : 'Cash'), notes: _notes.text.isEmpty ? null : _notes.text));
    _desc.clear(); _amt.clear(); _notes.clear(); setState(() => _showAdd = false);
  }
  @override
  void dispose() { _desc.dispose(); _amt.dispose(); _notes.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final accountNames = [...widget.banks.map((b) => b.name), 'Cash'];
    _account ??= accountNames.firstOrNull;
    final total = widget.transactions.fold(0.0, (s, t) => s + (t.isIncome ? 0 : t.amount));
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: AppColors.surface, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total spent', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary)),
        Text(_fmt(total), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
        ElevatedButton.icon(onPressed: () => setState(() => _showAdd = !_showAdd), icon: const Icon(Icons.add, size: 14), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 11, fontFamily: 'IBMPlexMono'))),
      ])),
      if (_showAdd) Container(padding: const EdgeInsets.all(12), color: AppColors.card, child: Column(children: [
        Row(children: [
          Expanded(child: AppTextField(controller: _desc, label: 'Description', hint: 'What was this?')),
          const Gap(8),
          SizedBox(width: 100, child: AppTextField(controller: _amt, label: 'Amount', keyboardType: TextInputType.number)),
        ]),
        const Gap(8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: _cat, dropdownColor: AppColors.card, decoration: const InputDecoration(labelText: 'Category'),
            items: AppConstants.txCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _cat = v!))),
          const Gap(8),
          Expanded(child: DropdownButtonFormField<String>(initialValue: _account, dropdownColor: AppColors.card, decoration: const InputDecoration(labelText: 'Account'),
            items: accountNames.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _account = v))),
        ]),
        const Gap(8),
        Row(children: [Expanded(child: ElevatedButton(onPressed: _add, child: const Text('Add Transaction'))), const Gap(8), Expanded(child: OutlinedButton(onPressed: () => setState(() => _showAdd = false), child: const Text('Cancel')))]),
      ])),
      Expanded(child: widget.transactions.isEmpty ? const Center(child: Text('No transactions yet.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))) : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: widget.transactions.length,
        itemBuilder: (_, i) {
          final tx = widget.transactions[i];
          return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                Text('${DateFormat('MMM d').format(tx.date)} · ${tx.accountName} · ${tx.category}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: AppColors.textSecondary)),
              ])),
              Text(_fmt(tx.amount), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), onPressed: () => widget.onDelete(tx.id)),
            ]));
        },
      )),
    ]);
  }
}

// ══ HABITS ════════════════════════════════════════════════════
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});
  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  final _nameCtrl = TextEditingController();
  final _iconCtrl = TextEditingController(text: '✅');
  bool _showAdd = false;
  @override
  void dispose() { _nameCtrl.dispose(); _iconCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Habits'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _showAdd = true)),
      ]),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e')),
        data: (habits) {
          final done = habits.where((h) => h.isDoneToday).length;
          final pct = habits.isEmpty ? 0.0 : done / habits.length;
          return ListView(padding: const EdgeInsets.all(14), children: [
            // Progress
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: Theme.of(context).textTheme.titleMedium),
                Text('$done/${habits.length}', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 18, fontWeight: FontWeight.w700, color: pct == 1 ? AppColors.deen : AppColors.gold)),
              ]),
              const Gap(8),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(pct == 1 ? AppColors.deen : AppColors.gold), minHeight: 7)),
            ])),
            const Gap(12),
            // Add form
            if (_showAdd) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.kyberia.withOpacity(0.3))), child: Column(children: [
              Row(children: [
                SizedBox(width: 60, child: AppTextField(controller: _iconCtrl, label: 'Icon')),
                const Gap(10),
                Expanded(child: AppTextField(controller: _nameCtrl, label: 'Habit name', autofocus: true)),
              ]),
              const Gap(10),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () { if (_nameCtrl.text.isNotEmpty) { notifier.addHabit(_nameCtrl.text, _iconCtrl.text); _nameCtrl.clear(); _iconCtrl.text = '✅'; setState(() => _showAdd = false); } }, child: const Text('Add'))),
                const Gap(8),
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _showAdd = false), child: const Text('Cancel'))),
              ]),
            ])),
            // Habits
            ...habits.asMap().entries.map((entry) {
              final h = entry.value;
              final isDone = h.isDoneToday;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(color: isDone ? AppColors.deen.withOpacity(0.07) : AppColors.card, borderRadius: BorderRadius.circular(12),
                  child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => notifier.toggle(h.id), child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isDone ? AppColors.deen.withOpacity(0.3) : AppColors.border)),
                    child: Row(children: [
                      Text(h.icon, style: const TextStyle(fontSize: 22)),
                      const Gap(12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(h.name, style: TextStyle(fontSize: 14, fontWeight: isDone ? FontWeight.w600 : FontWeight.w400, color: AppColors.textPrimary)),
                        if (h.streak > 0) Text('🔥 ${h.streak} day streak', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.gold)),
                      ])),
                      AnimatedContainer(duration: 200.ms, width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: isDone ? AppColors.deen.withOpacity(0.2) : Colors.transparent, border: Border.all(color: isDone ? AppColors.deen : AppColors.textSecondary.withOpacity(0.4), width: 2)),
                        child: Icon(isDone ? Icons.check : null, color: AppColors.deen, size: 18)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary), onPressed: () => notifier.deleteHabit(h.id)),
                    ]),
                  )),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: entry.key * 40));
            }),
          ]);
        },
      ),
    );
  }
}

// ══ GOALS ═════════════════════════════════════════════════════
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Pool'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context)),
      ]),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e')),
        data: (goals) {
          final sorted = [...goals]..sort((a, b) {
            if (a.status == b.status) return a.targetDate.compareTo(b.targetDate);
            return a.status == 'done' ? 1 : b.status == 'done' ? -1 : 0;
          });
          final active = goals.where((g) => g.status == 'active').length;
          final done = goals.where((g) => g.status == 'done').length;
          return ListView(padding: const EdgeInsets.all(14), children: [
            Row(children: [
              Expanded(child: _GoalStat('Active', '$active', AppColors.gold)),
              const Gap(8),
              Expanded(child: _GoalStat('Done', '$done', AppColors.deen)),
              const Gap(8),
              Expanded(child: _GoalStat('Total', '${goals.length}', AppColors.kyberia)),
            ]),
            const Gap(12),
            ...sorted.asMap().entries.map((e) => _GoalCard(goal: e.value).animate().fadeIn(delay: Duration(milliseconds: e.key * 40))),
          ]);
        },
      ),
    );
  }

  void _showAddDialog(BuildContext ctx) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => _GoalForm(onSave: (g) => ref.read(goalsProvider.notifier).addGoal(g)));
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat(this.label, this.value, this.color);
  final String label, value; final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Column(children: [Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 20, fontWeight: FontWeight.w700, color: color)), Text(label, style: Theme.of(context).textTheme.labelSmall)]));
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(goalsProvider.notifier);
    final pc = {'high': AppColors.error, 'medium': AppColors.gold, 'low': AppColors.deen}[goal.priority] ?? AppColors.gold;
    final isDone = goal.status == 'done';
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDone ? AppColors.done.withOpacity(0.3) : AppColors.border)),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: pc, shape: BoxShape.circle)),
          const Gap(6),
          Text(goal.priority.toUpperCase(), style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8.5, color: pc, letterSpacing: 0.8)),
          if (isDone) ...[const Gap(6), const Text('COMPLETE ✓', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8.5, color: AppColors.deen))],
          const Spacer(),
          PopupMenuButton<String>(iconSize: 16, color: AppColors.card, onSelected: (v) {
            if (v == 'done') n.setStatus(goal.id, 'done');
            else if (v == 'active') n.setStatus(goal.id, 'active');
            else if (v == 'pause') n.setStatus(goal.id, 'paused');
            else if (v == 'del') n.deleteGoal(goal.id);
          }, itemBuilder: (_) => [
            if (!isDone) const PopupMenuItem(value: 'done', child: Text('Mark Done ✓')),
            if (isDone) const PopupMenuItem(value: 'active', child: Text('Reopen')),
            if (goal.status == 'active') const PopupMenuItem(value: 'pause', child: Text('Pause')),
            if (goal.status == 'paused') const PopupMenuItem(value: 'active', child: Text('Resume')),
            const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: AppColors.error))),
          ]),
        ]),
        const Gap(6),
        Text(goal.title, style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16, fontWeight: FontWeight.w700, color: isDone ? AppColors.textSecondary : AppColors.textPrimary)),
        if (goal.description != null) Text(goal.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        const Gap(10),
        Row(children: [
          Expanded(child: Slider(value: goal.progress.toDouble(), min: 0, max: 100, divisions: 20, activeColor: pc, inactiveColor: AppColors.border, onChanged: (v) => n.setProgress(goal.id, v.round()))),
          SizedBox(width: 36, child: Text('${goal.progress}%', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: pc, fontWeight: FontWeight.w600))),
        ]),
        ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: goal.progress / 100, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(pc), minHeight: 5)),
        const Gap(8),
        Text(
          '🗓 ${DateFormat('MMM d, yyyy').format(goal.targetDate)}  ${goal.isOverdue ? "· OVERDUE" : goal.isDueSoon ? "· ${goal.daysRemaining}d left" : "· ${goal.daysRemaining}d"}',
          style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: goal.isOverdue ? AppColors.error : goal.isDueSoon ? AppColors.warning : AppColors.textSecondary),
        ),
      ])));
  }
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({required this.onSave});
  final void Function(Goal) onSave;
  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _title = TextEditingController(), _desc = TextEditingController();
  DateTime _target = DateTime.now().add(const Duration(days: 90));
  String _priority = 'medium';
  void _submit() { if (_title.text.isEmpty) return; widget.onSave(Goal(id: '', title: _title.text, targetDate: _target, description: _desc.text.isEmpty ? null : _desc.text, priority: _priority)); Navigator.pop(context); }
  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('New Goal', style: Theme.of(context).textTheme.headlineSmall),
      const Gap(14),
      AppTextField(controller: _title, label: 'Goal title', autofocus: true),
      const Gap(10),
      AppTextField(controller: _desc, label: 'Description (optional)', maxLines: 2),
      const Gap(10),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _target, firstDate: DateTime.now(), lastDate: DateTime(2030));
          if (d != null) setState(() => _target = d);
        }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Row(children: [const Icon(Icons.calendar_today, size: 14, color: AppColors.gold), const Gap(6), Text(DateFormat('MMM d, yyyy').format(_target), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary))])))),
        const Gap(10),
        Expanded(child: DropdownButtonFormField<String>(initialValue: _priority, dropdownColor: AppColors.card, decoration: const InputDecoration(labelText: 'Priority'),
          items: ['high','medium','low'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _priority = v!))),
      ]),
      const Gap(16),
      ElevatedButton(onPressed: _submit, child: const Text('Add Goal')),
    ])));
}

// ══ FOCUS ═════════════════════════════════════════════════════
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with SingleTickerProviderStateMixin {
  late final _tc = TabController(length: 3, vsync: this);
  Timer? _timer;
  DateTime? _startTime;
  final _noteCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tc.addListener(() => setState(() {})); }
  @override
  void dispose() { _timer?.cancel(); _noteCtrl.dispose(); _tc.dispose(); super.dispose(); }

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final t = ref.read(focusTimerProvider.notifier);
      t.tick();
      final state = ref.read(focusTimerProvider);
      if (state.secondsLeft == 0) {
        _timer?.cancel();
        _logSession(completed: true);
      }
    });
    ref.read(focusTimerProvider.notifier).start();
  }

  void _pauseTimer() {
    _timer?.cancel();
    ref.read(focusTimerProvider.notifier).pause();
  }

  void _resetTimer() {
    _timer?.cancel();
    if (_startTime != null) _logSession(completed: false);
    ref.read(focusTimerProvider.notifier).reset();
    _startTime = null;
  }

  void _logSession({required bool completed}) {
    if (_startTime == null) return;
    final state = ref.read(focusTimerProvider);
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    ref.read(focusSessionsProvider.notifier).logSession(FocusSession(
      id: '', date: DateTime.now(),
      blockLabel: state.selectedBlockLabel.isEmpty ? 'Free work' : state.selectedBlockLabel,
      blockCategoryKey: state.selectedBlockCategory,
      plannedSeconds: state.totalSeconds,
      actualSeconds: elapsed,
      completed: completed,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      startedAt: _startTime,
    ));
    _startTime = null;
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(focusTimerProvider);
    final mode = ref.watch(selectedScheduleModeProvider);
    final blocks = ref.watch(scheduleBlocksProvider(mode)).valueOrNull ?? kDefaultBlocks[mode] ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: Column(children: [
        TabBar(controller: _tc, tabs: const [Tab(text: '⏱ Timer'), Tab(text: '📋 Log'), Tab(text: '📊 Analytics')], labelColor: AppColors.gold, unselectedLabelColor: AppColors.textSecondary, indicatorColor: AppColors.gold, labelStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, fontWeight: FontWeight.w600)),
        Expanded(child: TabBarView(controller: _tc, children: [
          // Timer tab
          SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
            // Mode
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final m in [('focus', '🍅 Focus'), ('break', '☕ Break')])
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(
                  onTap: () => ref.read(focusTimerProvider.notifier).setMode(m.$1),
                  child: AnimatedContainer(duration: 150.ms, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: timer.mode == m.$1 ? AppColors.gold.withOpacity(0.15) : AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: timer.mode == m.$1 ? AppColors.gold : AppColors.border)),
                    child: Text(m.$2, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: timer.mode == m.$1 ? AppColors.gold : AppColors.textSecondary, fontWeight: timer.mode == m.$1 ? FontWeight.w700 : FontWeight.w400))),
                )),
            ]),
            const Gap(20),
            // Circular timer
            SizedBox(height: 220, width: 220, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: timer.progress, strokeWidth: 8, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(timer.isRunning ? AppColors.gold : AppColors.textSecondary))),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${timer.mm}:${timer.ss}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 2)),
                Text(timer.mode == 'focus' ? 'FOCUS' : 'BREAK', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary, letterSpacing: 2)),
              ]),
            ])),
            const Gap(20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(
                onPressed: timer.isRunning ? _pauseTimer : _startTimer,
                icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow, size: 20),
                label: Text(timer.isRunning ? 'Pause' : 'Start'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
              ),
              const Gap(12),
              OutlinedButton.icon(onPressed: _resetTimer, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
            ]),
            const Gap(20),
            // Block selector
            DropdownButtonFormField<String>(
              initialValue: timer.selectedBlockLabel.isEmpty ? null : timer.selectedBlockLabel,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(labelText: 'Link to schedule block (optional)'),
              items: [const DropdownMenuItem(value: null, child: Text('— Free work —', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12))),
                ...blocks.map((b) => DropdownMenuItem(value: b.label, child: Text('${b.time} · ${b.label}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11)))),
              ],
              onChanged: (v) {
                if (v == null) { ref.read(focusTimerProvider.notifier).selectBlock('', 'rest'); return; }
                final b = blocks.firstWhere((bl) => bl.label == v);
                ref.read(focusTimerProvider.notifier).selectBlock(b.label, b.categoryKey);
              },
            ),
            const Gap(10),
            AppTextField(controller: _noteCtrl, label: 'Session note (optional)', hint: 'What are you working on?'),
            const Gap(10),
            // Duration controls
            Row(children: [
              Expanded(child: AppTextField(controller: TextEditingController(text: timer.focusDuration.toString()), label: 'Focus (min)', keyboardType: TextInputType.number, onChanged: (v) { final f = int.tryParse(v); if (f != null) ref.read(focusTimerProvider.notifier).setDurations(f, timer.breakDuration); })),
              const Gap(10),
              Expanded(child: AppTextField(controller: TextEditingController(text: timer.breakDuration.toString()), label: 'Break (min)', keyboardType: TextInputType.number, onChanged: (v) { final b = int.tryParse(v); if (b != null) ref.read(focusTimerProvider.notifier).setDurations(timer.focusDuration, b); })),
            ]),
          ])),
          // Log tab
          ref.watch(focusSessionsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(child: Text('$e')),
            data: (sessions) => sessions.isEmpty ? const Center(child: Text('No sessions logged yet.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))) : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              itemBuilder: (_, i) {
                final s = sessions[i];
                final c = AppColors.categoryColor(s.blockCategoryKey);
                return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(width: 3, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(right: 10)),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.blockLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text('${DateFormat('MMM d').format(s.date)}${s.note != null ? ' · ${s.note}' : ''}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: AppColors.textSecondary)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${s.actualMinutes}m', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, fontWeight: FontWeight.w700, color: s.completed ? AppColors.deen : AppColors.warning)),
                      Text(s.completed ? '✓ done' : 'stopped', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: s.completed ? AppColors.deen : AppColors.warning)),
                    ]),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary), onPressed: () => ref.read(focusSessionsProvider.notifier).deleteSession(s.id)),
                  ]));
              },
            ),
          ),
          // Analytics tab
          ref.watch(focusSessionsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(child: Text('$e')),
            data: (sessions) {
              final notifier = ref.read(focusSessionsProvider.notifier);
              final byDay = notifier.last7DaysMinutes();
              final byCat = notifier.minutesByCategory;
              final maxDay = byDay.map((e) => e.value).fold(1, (a, b) => a > b ? a : b);
              return ListView(padding: const EdgeInsets.all(14), children: [
                Text('Last 7 Days', style: Theme.of(context).textTheme.titleLarge), const Gap(10),
                Container(height: 120, padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: byDay.map((e) => Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${e.value}m', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: AppColors.textSecondary)),
                  const Gap(3),
                  Flexible(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.5), AppColors.gold], begin: Alignment.bottomCenter, end: Alignment.topCenter), borderRadius: BorderRadius.circular(3)), height: maxDay > 0 ? (e.value / maxDay * 80).clamp(2.0, 80.0) : 2)),
                  const Gap(3),
                  Text(e.key, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: AppColors.textSecondary)),
                ]))).toList())),
                const Gap(16),
                Text('By Category', style: Theme.of(context).textTheme.titleLarge), const Gap(10),
                if (byCat.isEmpty) const Text('No sessions yet.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ...byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
                ..map((e) {
                  final c = AppColors.categoryColor(e.key);
                  final maxV = byCat.values.fold(1, (a, b) => a > b ? a : b);
                  return Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(categoryInfoMap[e.key]?.label ?? e.key, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)), Text('${e.value}m', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: c, fontWeight: FontWeight.w600))]),
                    const Gap(3),
                    ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: e.value / maxV, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(c), minHeight: 5)),
                  ]));
                }),
                const Gap(16),
                Text('Stats', style: Theme.of(context).textTheme.titleLarge), const Gap(10),
                ...{
                  'Total sessions': '${sessions.length}',
                  'Completed': '${sessions.where((s) => s.completed).length}',
                  'Total focus time': '${sessions.where((s) => s.completed).fold(0, (a, s) => a + s.actualMinutes)}m',
                  "Today's sessions": '${sessions.where((s) => isSameDay(s.date, DateTime.now())).length}',
                }.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)), Text(e.value, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))]))),
              ]);
            },
          ),
        ])),
      ]),
    );
  }
}
