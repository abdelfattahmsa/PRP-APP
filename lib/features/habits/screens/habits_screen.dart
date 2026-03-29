// ══════════════════════════════════════════════════════════════
// HABITS SCREEN
// ══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_text_field.dart';

const _uuid = Uuid();

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});
  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  bool _adding = false;
  final _name = TextEditingController();
  String _icon = '✅';

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  void _addHabit() {
    if (_name.text.isEmpty) return;
    final habit = Habit(id: _uuid.v4(), name: _name.text.trim(), icon: _icon, order: 99);
    ref.read(habitsProvider.notifier).add(habit);
    _name.clear(); _icon = '✅';
    setState(() => _adding = false);
  }

  String get _todayKey {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final progress   = ref.watch(habitsTodayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
        data: (habits) => ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          children: [
            // Progress card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Today's Habits", style: Theme.of(context).textTheme.titleLarge),
                  Text('${progress.done}/${progress.total}', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 20, fontWeight: FontWeight.w700, color: progress.pct == 1.0 ? AppColors.deen : AppColors.gold)),
                ]),
                const Gap(10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.pct,
                    minHeight: 8, backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(progress.pct == 1.0 ? AppColors.deen : AppColors.gold),
                  ),
                ),
                const Gap(6),
                Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary)),
              ]),
            ).animate().fadeIn(duration: 300.ms),
            const Gap(14),

            // Add habit
            if (_adding)
              Container(
                padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  Row(children: [
                    SizedBox(width: 60, child: AppTextField(controller: TextEditingController(text: _icon), label: 'Icon', onChanged: (v) => _icon = v)),
                    const Gap(10),
                    Expanded(child: AppTextField(controller: _name, label: 'Habit name', hint: 'e.g. Walk 30 min', autofocus: true, onChanged: (_) {})),
                  ]),
                  const Gap(10),
                  Row(children: [
                    Expanded(child: ElevatedButton(onPressed: _addHabit, child: const Text('Add'))),
                    const Gap(10),
                    Expanded(child: OutlinedButton(onPressed: () => setState(() { _adding = false; _name.clear(); }), child: const Text('Cancel'))),
                  ]),
                ]),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05),

            if (!_adding)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add New Habit'),
                  onPressed: () => setState(() => _adding = true),
                ),
              ),

            // Habit cards
            ...habits.asMap().entries.map((e) => _HabitTile(
              key: ValueKey(e.value.id),
              habit: e.value, index: e.key, todayKey: _todayKey,
            )),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({super.key, required this.habit, required this.index, required this.todayKey});
  final Habit habit;
  final int index;
  final String todayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = habit.isDoneToday;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('h_${habit.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        onDismissed: (_) => ref.read(habitsProvider.notifier).delete(habit.id),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: done ? AppColors.deen.withOpacity(0.06) : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: done ? AppColors.deen.withOpacity(0.25) : AppColors.border),
          ),
          child: Row(children: [
            Text(habit.icon, style: const TextStyle(fontSize: 22)),
            const Gap(12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(habit.name, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
              const Gap(2),
              Row(children: [
                if (habit.streak > 0) ...[
                  Text('🔥 ${habit.streak} day streak', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.gold)),
                  const Gap(8),
                ] else ...[
                  const Text('No streak yet', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary)),
                  const Gap(8),
                ],
                if (habit.longestStreak > 0)
                  Text('best: ${habit.longestStreak}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
              ]),
            ])),
            GestureDetector(
              onTap: () => ref.read(habitsProvider.notifier).toggle(habit.id, todayKey),
              child: AnimatedContainer(
                duration: 180.ms,
                width: 34, height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.deen.withOpacity(0.2) : AppColors.surface,
                  border: Border.all(color: done ? AppColors.deen : const Color(0xFF303040), width: 2),
                ),
                child: Center(
                  child: Icon(done ? Icons.check : Icons.circle_outlined, size: 18, color: done ? AppColors.deen : AppColors.textSecondary),
                ),
              ),
            ),
          ]),
        ),
      ).animate(delay: (index * 40).ms).fadeIn(duration: 200.ms).slideX(begin: -0.03),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GOALS SCREEN
// ══════════════════════════════════════════════════════════════

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  bool _adding = false;
  final _title = TextEditingController();
  final _desc  = TextEditingController();
  String _priority = 'high';
  DateTime _target = DateTime.now().add(const Duration(days: 30));
  int _progress = 0;

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

  void _add() {
    if (_title.text.isEmpty) return;
    ref.read(goalsProvider.notifier).add(Goal(id: _uuid.v4(), title: _title.text.trim(), targetDate: _target, description: _desc.text.trim().isEmpty ? null : _desc.text.trim(), priority: _priority, progress: _progress));
    _title.clear(); _desc.clear();
    setState(() { _adding = false; _priority = 'high'; _progress = 0; _target = DateTime.now().add(const Duration(days: 30)); });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _target,
      firstDate: DateTime.now(), lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.card)), child: child!),
    );
    if (d != null) setState(() => _target = d);
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Pool')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
        data: (goals) {
          final active = goals.where((g) => g.status == 'active').toList()..sort((a, b) => a.targetDate.compareTo(b.targetDate));
          final done   = goals.where((g) => g.status == 'done').toList();
          final paused = goals.where((g) => g.status == 'paused').toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            children: [
              // Stats row
              Row(children: [
                _GoalStat(label: 'Active',    value: '${active.length}',  color: AppColors.gold),
                const Gap(8),
                _GoalStat(label: 'Done',      value: '${done.length}',    color: AppColors.deen),
                const Gap(8),
                _GoalStat(label: 'Paused',    value: '${paused.length}',  color: AppColors.textSecondary),
              ]).animate().fadeIn(duration: 250.ms),
              const Gap(14),

              // Add form
              if (_adding) _GoalAddForm(
                title: _title, desc: _desc, priority: _priority, target: _target, progress: _progress,
                onPriorityChange: (v) => setState(() => _priority = v),
                onProgressChange: (v) => setState(() => _progress = v),
                onDateTap: _pickDate, onSave: _add,
                onCancel: () => setState(() { _adding = false; _title.clear(); _desc.clear(); }),
              ).animate().fadeIn(duration: 200.ms),

              if (!_adding) Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ElevatedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('New Goal'), onPressed: () => setState(() => _adding = true)),
              ),

              // Active
              if (active.isNotEmpty) ...[
                const _SectionHeader(label: 'ACTIVE GOALS'),
                ...active.asMap().entries.map((e) => _GoalTile(goal: e.value, index: e.key)),
              ],
              if (paused.isNotEmpty) ...[
                const Gap(10),
                const _SectionHeader(label: 'PAUSED'),
                ...paused.map((g) => _GoalTile(goal: g, index: 0)),
              ],
              if (done.isNotEmpty) ...[
                const Gap(10),
                const _SectionHeader(label: 'COMPLETED'),
                ...done.map((g) => _GoalTile(goal: g, index: 0, faded: true)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 22, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
    ]),
  ));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Divider(color: AppColors.border.withOpacity(0.6))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1.5))),
      Expanded(child: Divider(color: AppColors.border.withOpacity(0.6))),
    ]),
  );
}

class _GoalAddForm extends StatelessWidget {
  const _GoalAddForm({required this.title, required this.desc, required this.priority, required this.target, required this.progress, required this.onPriorityChange, required this.onProgressChange, required this.onDateTap, required this.onSave, required this.onCancel});
  final TextEditingController title, desc;
  final String priority;
  final DateTime target;
  final int progress;
  final void Function(String) onPriorityChange;
  final void Function(int) onProgressChange;
  final VoidCallback onDateTap, onSave, onCancel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppTextField(controller: title, label: 'Goal Title *', hint: 'What do you want to achieve?', autofocus: true),
      const Gap(10),
      AppTextField(controller: desc, label: 'Description', hint: 'How will you get there?'),
      const Gap(10),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Priority', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'IBMPlexMono')),
          const Gap(5),
          Row(children: ['high', 'medium', 'low'].map((p) {
            final sel = priority == p;
            final c = p == 'high' ? AppColors.error : p == 'medium' ? AppColors.gold : AppColors.deen;
            return Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onPriorityChange(p),
                child: AnimatedContainer(
                  duration: 120.ms,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: sel ? c.withOpacity(0.15) : AppColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: sel ? c.withOpacity(0.5) : AppColors.border)),
                  child: Center(child: Text(p, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: sel ? c : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))),
                ),
              ),
            ));
          }).toList()),
        ])),
        const Gap(10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Target Date *', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'IBMPlexMono')),
          const Gap(5),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                const Gap(6),
                Text(DateFormat('dd MMM yy').format(target), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textPrimary)),
              ]),
            ),
          ),
        ])),
      ]),
      const Gap(10),
      Row(children: [
        const Text('Starting progress:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'IBMPlexMono')),
        Expanded(child: Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, onChanged: (v) => onProgressChange(v.round()))),
        Text('$progress%', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.gold)),
      ]),
      Row(children: [
        Expanded(child: ElevatedButton(onPressed: onSave, child: const Text('Add Goal'))),
        const Gap(10),
        Expanded(child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
      ]),
    ]),
  );
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal, required this.index, this.faded = false});
  final Goal goal;
  final int index;
  final bool faded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priColor = goal.priority == 'high' ? AppColors.error : goal.priority == 'medium' ? AppColors.gold : AppColors.deen;
    final daysLeft = goal.daysRemaining;
    final daysColor = daysLeft < 0 ? AppColors.error : daysLeft < 14 ? AppColors.fasting : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: faded ? AppColors.card.withOpacity(0.6) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: goal.status == 'done' ? AppColors.done.withOpacity(0.3) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 4, decoration: BoxDecoration(color: priColor, shape: BoxShape.circle)),
            const Gap(6),
            Text(goal.priority.toUpperCase(), style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: priColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            if (goal.status == 'done') ...[
              const Gap(8),
              const Text('COMPLETE ✓', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, color: AppColors.deen, fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            Text(daysLeft < 0 ? 'Overdue' : daysLeft == 0 ? 'Today!' : '${daysLeft}d left', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: daysColor)),
          ]),
          const Gap(6),
          Text(goal.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: faded ? AppColors.textSecondary : AppColors.textPrimary)),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const Gap(3),
            Text(goal.description!, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          const Gap(10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Progress', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
                const Spacer(),
                Text('${goal.progress}%', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: priColor, fontWeight: FontWeight.w600)),
              ]),
              const Gap(4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: priColor, inactiveTrackColor: AppColors.border,
                  thumbColor: priColor, overlayColor: priColor.withOpacity(0.1),
                  trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: goal.progress.toDouble(), min: 0, max: 100, divisions: 20,
                  onChanged: (v) => ref.read(goalsProvider.notifier).setProgress(goal.id, v.round()),
                ),
              ),
            ])),
          ]),
          const Gap(6),
          Row(children: [
            Text(DateFormat('d MMM yy').format(goal.targetDate), style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: AppColors.textSecondary)),
            const Spacer(),
            if (goal.status == 'active') ...[
              _StatusBtn(label: 'Done ✓', color: AppColors.deen, onTap: () => ref.read(goalsProvider.notifier).setStatus(goal.id, 'done')),
              const Gap(6),
              _StatusBtn(label: 'Pause', color: AppColors.textSecondary, onTap: () => ref.read(goalsProvider.notifier).setStatus(goal.id, 'paused')),
            ] else if (goal.status == 'done') ...[
              _StatusBtn(label: 'Reopen', color: AppColors.textSecondary, onTap: () => ref.read(goalsProvider.notifier).setStatus(goal.id, 'active')),
            ] else ...[
              _StatusBtn(label: 'Resume', color: AppColors.gold, onTap: () => ref.read(goalsProvider.notifier).setStatus(goal.id, 'active')),
            ],
            const Gap(6),
            GestureDetector(
              onTap: () => ref.read(goalsProvider.notifier).delete(goal.id),
              child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            ),
          ]),
        ]),
      ).animate(delay: (index * 40).ms).fadeIn(duration: 200.ms),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  const _StatusBtn({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.5, color: color, fontWeight: FontWeight.w600)),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// FOCUS SCREEN  (Pomodoro + Analytics)
// ══════════════════════════════════════════════════════════════

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    // Start the ticker
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
    final elapsed = state.startedAt != null ? DateTime.now().difference(state.startedAt!).inSeconds : state.plannedSeconds;
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
            initialValue: state.selectedBlockLabel.isEmpty ? null : state.selectedBlockLabel,
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
      error: (e, _) => Center(child: Text('$e')),
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
      error: (e, _) => Center(child: Text('$e')),
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
