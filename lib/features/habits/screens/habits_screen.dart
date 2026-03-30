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
        error: (e, _) => Center(child: Text('Unable to load habits. Please try again.', style: const TextStyle(color: AppColors.error))),
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
