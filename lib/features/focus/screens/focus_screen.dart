// ======================================================================
// FOCUS SCREEN  (Pomodoro + Analytics)
// ======================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';

const _uuid = Uuid();

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTicker();
    });
  }

  void _startTicker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      ref.read(focusTimerProvider.notifier).tick();
      final state = ref.read(focusTimerProvider);
      if (state.secondsLeft == 0 && state.isRunning == false) {
        _onTimerComplete(state);
      }
      return true;
    });
  }

  void _onTimerComplete(FocusTimerState state) {
    final elapsed = state.startedAt != null ? DateTime.now().difference(state.startedAt!).inSeconds : state.totalSeconds;
    final session = FocusSession(
      id: _uuid.v4(), date: DateTime.now(),
      blockLabel: state.selectedBlockLabel.isEmpty ? 'Free session' : state.selectedBlockLabel,
      blockCategoryKey: state.selectedBlockCategory,
      plannedSeconds: state.totalSeconds,
      actualSeconds: elapsed, completed: true,
      note: state.note.isNotEmpty ? state.note : null,
      startedAt: state.startedAt,
    );
    ref.read(focusSessionsProvider.notifier).add(session);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.mode == 'focus' ? '🍅 Focus session complete!' : '☕ Break over!')),
    );
  }

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
            labelStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, fontWeight: FontWeight.w600),
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
                    color: state.mode == m.$1 ? color.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: state.mode == m.$1 ? color.withOpacity(0.4) : Colors.transparent),
                  ),
                  child: Center(child: Text(m.$2, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: state.mode == m.$1 ? color : AppColors.textSecondary, fontWeight: state.mode == m.$1 ? FontWeight.w700 : FontWeight.w400))),
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
                valueColor: AlwaysStoppedAnimation(color.withOpacity(state.isRunning ? 1.0 : 0.4)),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (state.selectedBlockLabel.isNotEmpty)
                Text(state.selectedBlockLabel, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
              const Gap(4),
              Text('$mm:$ss', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 52, fontWeight: FontWeight.w700, color: state.isRunning ? color : AppColors.textPrimary)),
              Text(state.mode == 'focus' ? 'FOCUS' : 'BREAK', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2)),
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
          const Text('Link to block:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'IBMPlexMono')),
          const Gap(6),
          DropdownButtonFormField<String>(
            value: state.selectedBlockLabel.isEmpty ? null : state.selectedBlockLabel,
            hint: const Text('— Select schedule block —', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'IBMPlexMono')),
            dropdownColor: AppColors.card,
            items: blocks.map((b) => DropdownMenuItem(value: b.label, child: Text('${b.time} · ${b.label}', style: const TextStyle(fontSize: 11, fontFamily: 'IBMPlexMono')))).toList(),
            onChanged: (v) { if (v != null) { final b = blocks.firstWhere((b) => b.label == v); notifier.selectBlock(b.label, b.categoryKey); } },
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
          ),
          const Gap(12),
          TextField(
            onChanged: (v) => notifier.setNote(v),
            maxLines: 2, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12),
            decoration: const InputDecoration(hintText: 'Session note (optional)...', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'IBMPlexMono'), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
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
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: large ? 15 : 12, fontWeight: FontWeight.w700, color: color)),
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
      Text('$label:', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: color)),
      const Spacer(),
      IconButton(icon: const Icon(Icons.remove, size: 14), onPressed: () => onChange(value > 1 ? value - 1 : 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      Text(' $value min ', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
      error: (e, _) => Center(child: Text('Unable to load sessions. Please try again.', style: const TextStyle(color: AppColors.error))),
      data: (sessions) => sessions.isEmpty
          ? const Center(child: Text('No sessions yet', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                final color = AppColors.categoryColor(s.blockCategoryKey);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const Gap(12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.blockLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${DateFormat('d MMM · HH:mm').format(s.date)}${s.note != null ? ' · ${s.note}' : ''}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: AppColors.textSecondary)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${s.actualMinutes}m', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 15, color: s.completed ? AppColors.deen : AppColors.fasting, fontWeight: FontWeight.w700)),
                      Text(s.completed ? 'done' : 'stopped', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
                    ]),
                  ]),
                );
              },
            ),
    );
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
                const Text('LAST 7 DAYS · FOCUS MINUTES', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.gold, letterSpacing: 1.5)),
                const Gap(14),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: byDay.map((d) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(children: [
                    Text('${d.mins}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
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
                    Text(DateFormat('EEE').format(d.d).substring(0, 2), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: AppColors.textSecondary)),
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
                const Text('TIME BY CATEGORY', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.gold, letterSpacing: 1.5)),
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
                        Text('${e.value}m', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: color, fontWeight: FontWeight.w600)),
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
                      Text(row[1], style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
