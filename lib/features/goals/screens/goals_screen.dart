// ======================================================================
// GOALS SCREEN
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
import '../../../shared/widgets/app_text_field.dart';

const _uuid = Uuid();

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
        error: (e, _) => Center(child: Text('Unable to load goals. Please try again.', style: const TextStyle(color: AppColors.error))),
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
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
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
      Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1.5))),
      Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
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
          const Text('Priority', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                  decoration: BoxDecoration(color: sel ? c.withValues(alpha: 0.15) : AppColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: sel ? c.withValues(alpha: 0.5) : AppColors.border)),
                  child: Center(child: Text(p, style: TextStyle(fontSize: 10, color: sel ? c : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))),
                ),
              ),
            ));
          }).toList()),
        ])),
        const Gap(10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Target Date *', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const Gap(5),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                const Gap(6),
                Text(DateFormat('dd MMM yy').format(target), style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
              ]),
            ),
          ),
        ])),
      ]),
      const Gap(10),
      Row(children: [
        const Text('Starting progress:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Expanded(child: Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, onChanged: (v) => onProgressChange(v.round()))),
        Text('$progress%', style: const TextStyle(fontSize: 11, color: AppColors.gold)),
      ]),
      Row(children: [
        Expanded(child: ElevatedButton(onPressed: onSave, child: const Text('Add Goal'))),
        const Gap(10),
        Expanded(child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
      ]),
    ]),
  );
}

class _GoalTile extends ConsumerStatefulWidget {
  const _GoalTile({required this.goal, required this.index, this.faded = false});
  final Goal goal;
  final int index;
  final bool faded;

  @override
  ConsumerState<_GoalTile> createState() => _GoalTileState();
}

class _GoalTileState extends ConsumerState<_GoalTile> {
  bool _expanded = false;
  bool _addingSubtask = false;
  final _subtaskCtrl = TextEditingController();

  @override
  void dispose() {
    _subtaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final priColor = goal.priority == 'high' ? AppColors.error : goal.priority == 'medium' ? AppColors.gold : AppColors.deen;
    final daysLeft = goal.daysRemaining;
    final daysColor = daysLeft < 0 ? AppColors.error : daysLeft < 14 ? AppColors.fasting : AppColors.textSecondary;
    final doneCount = goal.subtasks.where((s) => s.done).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.faded ? AppColors.card.withValues(alpha: 0.6) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: goal.status == 'done' ? AppColors.done.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 4, decoration: BoxDecoration(color: priColor, shape: BoxShape.circle)),
            const Gap(6),
            Text(goal.priority.toUpperCase(), style: TextStyle(fontSize: 8, color: priColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            if (goal.status == 'done') ...[
              const Gap(8),
              const Text('COMPLETE ✓', style: TextStyle(fontSize: 8, color: AppColors.deen, fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            Text(daysLeft < 0 ? 'Overdue' : daysLeft == 0 ? 'Today!' : '${daysLeft}d left', style: TextStyle(fontSize: 9, color: daysColor)),
          ]),
          const Gap(6),
          Text(goal.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: widget.faded ? AppColors.textSecondary : AppColors.textPrimary)),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const Gap(3),
            Text(goal.description!, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          const Gap(10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Progress', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                const Spacer(),
                Text('${goal.progress}%', style: TextStyle(fontSize: 10, color: priColor, fontWeight: FontWeight.w600)),
              ]),
              const Gap(4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: priColor, inactiveTrackColor: AppColors.border,
                  thumbColor: priColor, overlayColor: priColor.withValues(alpha: 0.1),
                  trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: goal.progress.toDouble(), min: 0, max: 100, divisions: 20,
                  onChanged: (v) => ref.read(goalsProvider.notifier).setProgress(goal.id, v.round()),
                ),
              ),
            ])),
          ]),

          // ── Subtasks toggle ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14, color: AppColors.textSecondary),
                const Gap(4),
                Text(
                  goal.subtasks.isEmpty
                      ? 'Subtasks'
                      : '$doneCount/${goal.subtasks.length} done',
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary),
                ),
              ]),
            ),
          ),

          if (_expanded) ...[
            const Gap(4),
            ...goal.subtasks.map((sub) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                GestureDetector(
                  onTap: () => ref.read(goalsProvider.notifier).toggleSubtask(goal.id, sub.id),
                  child: Icon(
                    sub.done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: sub.done ? AppColors.deen : AppColors.textSecondary,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    sub.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: sub.done ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: sub.done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(goalsProvider.notifier).deleteSubtask(goal.id, sub.id),
                  child: const Icon(Icons.close, size: 12, color: AppColors.textSecondary),
                ),
              ]),
            )),
            if (_addingSubtask)
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Add subtask…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        ref.read(goalsProvider.notifier).addSubtask(goal.id, v.trim());
                      }
                      _subtaskCtrl.clear();
                      setState(() => _addingSubtask = false);
                    },
                  ),
                ),
                const Gap(6),
                GestureDetector(
                  onTap: () => setState(() => _addingSubtask = false),
                  child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                ),
              ])
            else
              GestureDetector(
                onTap: () => setState(() => _addingSubtask = true),
                child: Row(children: const [
                  Icon(Icons.add, size: 12, color: AppColors.textSecondary),
                  Gap(4),
                  Text('Add subtask', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ]),
              ),
            const Gap(6),
          ],

          const Gap(2),
          Row(children: [
            Text(DateFormat('d MMM yy').format(goal.targetDate), style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
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
      ).animate(delay: (widget.index * 40).ms).fadeIn(duration: 200.ms),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w600)),
    ),
  );
}
