// ======================================================================
// FOCUS SCREEN  (Pomodoro + Analytics)
// ======================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

// Session saving + notifications on completion are handled in ShellScreen
// (root-level listener) so they fire even when this screen is not active.
class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus Timer'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold, labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w600),
            tabs: [Tab(text: 'TIMER'), Tab(text: 'LOG'), Tab(text: 'ANALYTICS')],
          ),
        ),
        body: TabBarView(children: [
          const _FocusTimerView(),
          const _FocusLogView(),
          const _FocusAnalyticsView(),
        ]),
      ),
    );
  }
}

class _FocusTimerView extends ConsumerWidget {
  const _FocusTimerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);
    final blocksAsync = ref.watch(scheduleProvider('normal'));
    final blocks = blocksAsync.value ?? [];

    final mm = (state.secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (state.secondsLeft % 60).toString().padLeft(2, '0');
    final color = state.mode == 'focus' ? AppColors.gold : AppColors.deen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Mode selector
        Container(
          height: 44,
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            for (final m in [('focus', '🍅 Focus'), ('break', '☕ Break')]) ...[
              Expanded(child: GestureDetector(
                onTap: () => notifier.setMode(m.$1),
                child: AnimatedContainer(
                  duration: 150.ms, margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: state.mode == m.$1 ? color.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: state.mode == m.$1 ? color.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Center(child: Text(m.$2, style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: state.mode == m.$1 ? color : AppColors.textSecondary, fontWeight: state.mode == m.$1 ? FontWeight.w700 : FontWeight.w400))),
                ),
              )),
            ]
          ]),
        ),
        const Gap(20),

        // Timer circle
        SizedBox(
          width: 220, height: 220,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 220, height: 220,
              child: CircularProgressIndicator(
                value: state.progress,
                strokeWidth: 8, backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color.withValues(alpha: state.isRunning ? 1.0 : 0.4)),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (state.selectedBlockLabel.isNotEmpty)
                Text(state.selectedBlockLabel, style: const TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
              const Gap(4),
              Text('$mm:$ss', style: TextStyle(fontFamily: 'Roboto', fontSize: 52, fontWeight: FontWeight.w700, color: state.isRunning ? color : AppColors.textPrimary)),
              Text(state.mode == 'focus' ? 'FOCUS' : 'BREAK', style: const TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2)),
            ]),
          ]),
        ),
        const Gap(20),

        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _TimerBtn(
            label: state.isRunning ? '⏸ Pause' : '▶ Start',
            color: color, large: true,
            onTap: state.isRunning ? notifier.pause : notifier.start,
          ),
          const Gap(12),
          _TimerBtn(label: '↺ Reset', color: AppColors.textSecondary, onTap: notifier.reset),
        ]),
        const Gap(20),

        // Duration
        Row(children: [
          _DurControl(label: 'Focus', value: state.focusDuration, color: AppColors.gold,
              onChange: (v) => notifier.setDuration(v, state.breakDuration)),
          const Gap(10),
          _DurControl(label: 'Break', value: state.breakDuration, color: AppColors.deen,
              onChange: (v) => notifier.setDuration(state.focusDuration, v)),
        ]),
        const Gap(16),

        // Block selector
        if (blocks.isNotEmpty) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Link to block:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'Roboto')),
          const Gap(6),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: state.selectedBlockLabel.isEmpty ? null : state.selectedBlockLabel,
            hint: const Text('— Select schedule block —', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Roboto')),
            dropdownColor: AppColors.card,
            items: blocks.map((b) => DropdownMenuItem(value: b.label, child: Text('${b.time} · ${b.label}', style: const TextStyle(fontSize: 11, fontFamily: 'Roboto')))).toList(),
            onChanged: (v) { if (v != null) { final b = blocks.firstWhere((b) => b.label == v); notifier.selectBlock(b.label, b.categoryKey); } },
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
          ),
          const Gap(12),
          TextField(
            onChanged: (v) => notifier.setNote(v),
            maxLines: 2, style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
            decoration: const InputDecoration(hintText: 'Session note (optional)...', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Roboto'), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
          ),
        ]),
      ]),
    );
  }
}

class _TimerBtn extends StatelessWidget {
  const _TimerBtn({required this.label, required this.color, required this.onTap, this.large = false});
  final String label; final Color color; final VoidCallback onTap; final bool large;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 32 : 20, vertical: large ? 14 : 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(fontFamily: 'Roboto', fontSize: large ? 15 : 12, fontWeight: FontWeight.w700, color: color)),
    ),
  );
}

class _DurControl extends StatelessWidget {
  const _DurControl({required this.label, required this.value, required this.color, required this.onChange});
  final String label; final int value; final Color color; final void Function(int) onChange;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Text('$label:', style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: color)),
      const Spacer(),
      IconButton(icon: const Icon(Icons.remove, size: 14), onPressed: () => onChange(value > 1 ? value - 1 : 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      Text(' $value min ', style: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      IconButton(icon: const Icon(Icons.add, size: 14), onPressed: () => onChange(value + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
    ]),
  ));
}

class _FocusLogView extends ConsumerWidget {
  const _FocusLogView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessAsync = ref.watch(focusSessionsProvider);
    return sessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => const Center(child: Text('Unable to load sessions.', style: TextStyle(color: AppColors.error))),
      data: (sessions) => sessions.isEmpty
          ? const Center(child: Text('No sessions yet', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) => _SessionLogTile(session: sessions[i]),
            ),
    );
  }
}

class _SessionLogTile extends ConsumerWidget {
  const _SessionLogTile({required this.session});
  final FocusSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.categoryColor(session.blockCategoryKey);
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete session?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ),
      onDismissed: (_) => ref.read(focusSessionsProvider.notifier).delete(session.id),
      child: GestureDetector(
        onTap: () => _showEditDialog(context, ref),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const Gap(12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(session.blockLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text('${DateFormat('d MMM · HH:mm').format(session.date)}${session.note != null ? ' · ${session.note}' : ''}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 9.5, color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${session.actualMinutes}m', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, color: session.completed ? AppColors.deen : AppColors.fasting, fontWeight: FontWeight.w700)),
              Text(session.completed ? 'done' : 'stopped', style: const TextStyle(fontFamily: 'Roboto', fontSize: 9, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final labelCtrl = TextEditingController(text: session.blockLabel);
    final noteCtrl = TextEditingController(text: session.note ?? '');
    String category = session.blockCategoryKey;
    const cats = ['deen', 'learn', 'project', 'health', 'work', 'rest', 'fast', 'com'];
    const catLabels = ['Deen', 'Learning', 'Project', 'Health', 'Work', 'Rest', 'Fasting', 'Commute'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: const Text('Edit Session'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const Gap(12),
          DropdownButtonFormField<String>(
            initialValue: cats.contains(category) ? category : 'rest',
            decoration: const InputDecoration(labelText: 'Category'),
            items: List.generate(cats.length, (i) =>
              DropdownMenuItem(value: cats[i], child: Text(catLabels[i]))),
            onChanged: (v) => setS(() => category = v!),
          ),
          const Gap(12),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final updated = session.copyWith(
                blockLabel: labelCtrl.text.trim().isEmpty ? session.blockLabel : labelCtrl.text.trim(),
                blockCategoryKey: category,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                clearNote: noteCtrl.text.trim().isEmpty,
              );
              ref.read(focusSessionsProvider.notifier).updateSession(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
    labelCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _FocusAnalyticsView extends ConsumerWidget {
  const _FocusAnalyticsView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessAsync = ref.watch(focusSessionsProvider);
    return sessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text('Unable to load analytics. Please try again.', style: const TextStyle(color: AppColors.error))),
      data: (sessions) {
        final today7 = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
        final byDay = today7.map((d) {
          final key = DateFormat('yyyy-MM-dd').format(d);
          final mins = sessions.where((s) => DateFormat('yyyy-MM-dd').format(s.date) == key && s.completed).fold(0, (sum, s) => sum + s.actualMinutes);
          return (d: d, mins: mins);
        }).toList();
        final maxMins = byDay.fold(1, (m, d) => d.mins > m ? d.mins : m);

        final byCat = <String, int>{};
        for (final s in sessions.where((s) => s.completed)) {
          byCat[s.blockCategoryKey] = (byCat[s.blockCategoryKey] ?? 0) + s.actualMinutes;
        }
        final catEntries = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final maxCat = catEntries.isEmpty ? 1 : catEntries.first.value;

        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todaySessions = sessions.where((s) => DateFormat('yyyy-MM-dd').format(s.date) == todayStr).length;
        final totalMins = sessions.where((s) => s.completed).fold(0, (s, sess) => s + sess.actualMinutes);
        final avgMins = sessions.isEmpty ? 0 : (sessions.fold(0, (s, sess) => s + sess.actualMinutes) / sessions.length).round();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 7-day bar chart
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('LAST 7 DAYS · FOCUS MINUTES', style: TextStyle(fontFamily: 'Roboto', fontSize: 9, color: AppColors.gold, letterSpacing: 1.5)),
                const Gap(14),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: byDay.map((d) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(children: [
                    Text('${d.mins}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 9, color: AppColors.textSecondary)),
                    const Gap(3),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: 500.ms,
                          height: maxMins > 0 ? 60 * (d.mins / maxMins) : 0,
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                    ),
                    const Gap(4),
                    Text(DateFormat('EEE').format(d.d).substring(0, 2), style: const TextStyle(fontFamily: 'Roboto', fontSize: 8, color: AppColors.textSecondary)),
                  ]),
                ))).toList()),
              ]),
            ),
            const Gap(12),
            // By category
            if (catEntries.isNotEmpty) Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TIME BY CATEGORY', style: TextStyle(fontFamily: 'Roboto', fontSize: 9, color: AppColors.gold, letterSpacing: 1.5)),
                const Gap(12),
                ...catEntries.take(6).map((e) {
                  final color = AppColors.categoryColor(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                        const Gap(8),
                        Expanded(child: Text(e.key, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary))),
                        Text('${e.value}m', style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                      ]),
                      const Gap(4),
                      ClipRRect(borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: e.value / maxCat, minHeight: 4, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color))),
                    ]),
                  );
                }),
              ]),
            ),
            const Gap(12),
            // Stats
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                for (final row in [
                  ['Total sessions', '${sessions.length}'],
                  ['Completed', '${sessions.where((s) => s.completed).length}'],
                  ['Total focus time', '${totalMins}m'],
                  ["Today's sessions", '$todaySessions'],
                  ['Avg session', '${avgMins}m'],
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(row[0], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(row[1], style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const Divider(height: 1),
                ],
              ]),
            ),
          ],
        );
      },
    );
  }
}