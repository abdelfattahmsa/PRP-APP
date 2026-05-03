import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;
import '../../../engines/categories/data/models/user_category_model.dart';

const _uuid = Uuid();

enum _TaskSource { all, tasks, goals, habits }

class TimeTasksScreen extends ConsumerStatefulWidget {
  const TimeTasksScreen({super.key});

  @override
  ConsumerState<TimeTasksScreen> createState() => _TimeTasksScreenState();
}

class _TimeTasksScreenState extends ConsumerState<TimeTasksScreen> {
  _TaskSource _filter = _TaskSource.all;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final tasksAsync = ref.watch(tasksProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final habitsAsync = ref.watch(habitsProvider);

    final tasks = (tasksAsync.value ?? [])
        .where((t) => !t.completed)
        .toList();
    final completedTasks = (tasksAsync.value ?? [])
        .where((t) => t.completed)
        .toList();
    final goals = goalsAsync.value ?? [];
    final habits = habitsAsync.value ?? [];

    final activeGoals = goals
        .where((g) => g.status == 'active')
        .toList()
      ..sort((a, b) {
        const rank = {'high': 0, 'medium': 1, 'low': 2};
        return (rank[a.priority] ?? 1).compareTo(rank[b.priority] ?? 1);
      });
    final activeHabits = habits.where((h) => !h.isArchived).toList();

    final isLoading =
        tasksAsync.isLoading || goalsAsync.isLoading || habitsAsync.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: ScreenHeader(
                title: 'Tasks',
                subtitle: 'Manual tasks, goals and habits',
                action: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showAddTaskSheet(context, ref),
                  tooltip: 'Add task',
                ),
              ),
            ),
            const Gap(16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: tasks.length + activeGoals.length + activeHabits.length,
                    selected: _filter == _TaskSource.all,
                    onTap: () => setState(() => _filter = _TaskSource.all),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Tasks',
                    count: tasks.length,
                    selected: _filter == _TaskSource.tasks,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => setState(() => _filter = _TaskSource.tasks),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Goals',
                    count: activeGoals.length,
                    selected: _filter == _TaskSource.goals,
                    color: AppColors.learn,
                    onTap: () => setState(() => _filter = _TaskSource.goals),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Habits',
                    count: activeHabits.length,
                    selected: _filter == _TaskSource.habits,
                    color: AppColors.health,
                    onTap: () => setState(() => _filter = _TaskSource.habits),
                  ),
                ],
              ),
            ),
            const Gap(16),

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    // ── Manual Tasks ─────────────────────────────────
                    if (_filter != _TaskSource.goals &&
                        _filter != _TaskSource.habits &&
                        tasks.isNotEmpty) ...[
                      _SectionLabel(
                          '📋 Tasks (${tasks.length})', textSecondary),
                      const Gap(8),
                      ...tasks.map((t) => _UserTaskCard(
                            task: t,
                            textSecondary: textSecondary,
                            onComplete: () => ref
                                .read(tasksProvider.notifier)
                                .toggleComplete(t.id),
                            onEdit: () =>
                                _showAddTaskSheet(context, ref, existing: t),
                            onDelete: () => ref
                                .read(tasksProvider.notifier)
                                .delete(t.id),
                          )),
                      const Gap(16),
                    ],

                    // ── Goals ─────────────────────────────────────────
                    if (_filter != _TaskSource.tasks &&
                        _filter != _TaskSource.habits &&
                        activeGoals.isNotEmpty) ...[
                      _SectionLabel(
                          '🎯 Goals (${activeGoals.length})', textSecondary),
                      const Gap(8),
                      ...activeGoals.map((g) => _GoalTaskCard(
                            goal: g,
                            textSecondary: textSecondary,
                            ref: ref,
                          )),
                      const Gap(16),
                    ],

                    // ── Habits ────────────────────────────────────────
                    if (_filter != _TaskSource.tasks &&
                        _filter != _TaskSource.goals &&
                        activeHabits.isNotEmpty) ...[
                      _SectionLabel(
                          '🔁 Habits (${activeHabits.length})',
                          textSecondary),
                      const Gap(8),
                      ...activeHabits.map((h) => _HabitTaskCard(
                            habit: h,
                            textSecondary: textSecondary,
                            ref: ref,
                          )),
                      const Gap(16),
                    ],

                    // ── Completed Tasks ───────────────────────────────
                    if ((_filter == _TaskSource.all ||
                            _filter == _TaskSource.tasks) &&
                        completedTasks.isNotEmpty) ...[
                      _SectionLabel(
                          '✅ Completed (${completedTasks.length})',
                          textSecondary),
                      const Gap(8),
                      ...completedTasks.map((t) => _UserTaskCard(
                            task: t,
                            textSecondary: textSecondary,
                            onComplete: () => ref
                                .read(tasksProvider.notifier)
                                .toggleComplete(t.id),
                            onEdit: () =>
                                _showAddTaskSheet(context, ref, existing: t),
                            onDelete: () => ref
                                .read(tasksProvider.notifier)
                                .delete(t.id),
                          )),
                      const Gap(16),
                    ],

                    if (tasks.isEmpty &&
                        completedTasks.isEmpty &&
                        (_filter == _TaskSource.tasks))
                      _EmptyState(textSecondary: textSecondary,
                        onAdd: () => _showAddTaskSheet(context, ref)),

                    if (tasks.isEmpty &&
                        completedTasks.isEmpty &&
                        activeGoals.isEmpty &&
                        activeHabits.isEmpty)
                      _EmptyState(textSecondary: textSecondary,
                        onAdd: () => _showAddTaskSheet(context, ref)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD / EDIT TASK SHEET
// ══════════════════════════════════════════════════════════════

Future<void> _showAddTaskSheet(
  BuildContext context,
  WidgetRef ref, {
  UserTask? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _AddTaskSheet(existing: existing),
    ),
  );
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet({this.existing});
  final UserTask? existing;

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  String _categoryKey = 'work';
  int _durationMinutes = 30;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _categoryKey = t.categoryKey;
      _durationMinutes = t.durationMinutes;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _saving = false);
      return;
    }
    final task = UserTask(
      id: widget.existing?.id ?? _uuid.v4(),
      userId: user.id,
      title: title,
      categoryKey: _categoryKey,
      durationMinutes: _durationMinutes,
      dueDate: _dueDate,
      completed: widget.existing?.completed ?? false,
      order: widget.existing?.order ?? 0,
    );
    try {
      if (widget.existing != null) {
        await ref.read(tasksProvider.notifier).updateTask(task);
      } else {
        await ref.read(tasksProvider.notifier).add(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final scheduleCats = ref.watch(scheduleCategoriesProvider);
    final cats = scheduleCats.isNotEmpty
        ? scheduleCats
        : [
            for (final k in AppConstants.categoryKeys)
              UserCategory(
                id: k,
                name: categoryInfoMap[k]?.label ?? k,
                emoji: categoryInfoMap[k]?.emoji ?? '📌',
                engine: 'schedule',
                key: k,
                order: 0,
              )
          ];

    // Ensure _categoryKey is in the list
    if (!cats.any((c) => c.storageKey == _categoryKey)) {
      _categoryKey = cats.first.storageKey;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              widget.existing == null ? 'Add Task' : 'Edit Task',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Gap(20),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const Gap(12),

            // Category + Duration row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryKey,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: cats
                        .map((c) => DropdownMenuItem(
                              value: c.storageKey,
                              child: Text('${c.emoji} ${c.name}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryKey = v!),
                  ),
                ),
                const Gap(10),
                Expanded(
                  flex: 2,
                  child: _DurationPicker(
                    value: _durationMinutes,
                    border: border,
                    accent: accent,
                    onChanged: (v) => setState(() => _durationMinutes = v),
                  ),
                ),
              ],
            ),
            const Gap(12),

            // Due date
            OutlinedButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(
                _dueDate == null
                    ? 'Set due date (optional)'
                    : 'Due: ${DateFormat('MMM d, yyyy').format(_dueDate!)}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _dueDate != null ? accent : textSecondary,
              ),
            ),
            if (_dueDate != null) ...[
              const Gap(4),
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: Text('Clear due date',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        decoration: TextDecoration.underline)),
              ),
            ],
            const Gap(24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.existing == null ? 'Add Task' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Duration +/- picker widget
class _DurationPicker extends StatelessWidget {
  const _DurationPicker({
    required this.value,
    required this.border,
    required this.accent,
    required this.onChanged,
  });
  final int value;
  final Color border;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Duration',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor)),
          const Gap(4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: value > 5 ? () => onChanged(value - 5) : null,
                child: Icon(Icons.remove_circle_outline_rounded,
                    size: 20,
                    color: value > 5 ? accent : AppColors.textSecondary),
              ),
              Text('${value}m',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              GestureDetector(
                onTap: value < 480 ? () => onChanged(value + 5) : null,
                child: Icon(Icons.add_circle_outline_rounded,
                    size: 20,
                    color: value < 480 ? accent : AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TASK CARD
// ══════════════════════════════════════════════════════════════

class _UserTaskCard extends StatelessWidget {
  const _UserTaskCard({
    required this.task,
    required this.textSecondary,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });
  final UserTask task;
  final Color textSecondary;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final info = categoryInfoMap[task.categoryKey];
    final catColor = _catColor(task.categoryKey);
    final fmt = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_rounded, color: AppColors.error),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete task?'),
              content: Text('Remove "${task.title}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete(),
        child: AppCard(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: task.completed
                          ? catColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                          color: task.completed ? catColor : AppColors.border,
                          width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: task.completed
                        ? Icon(Icons.check_rounded, size: 14, color: catColor)
                        : null,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed ? textSecondary : null,
                        ),
                      ),
                      const Gap(3),
                      Row(
                        children: [
                          Text(
                            '${info?.emoji ?? '📌'} ${info?.label ?? task.categoryKey}',
                            style: TextStyle(
                                fontSize: 11,
                                color: catColor,
                                fontWeight: FontWeight.w500),
                          ),
                          const Gap(8),
                          Icon(Icons.timer_outlined,
                              size: 11, color: textSecondary),
                          const Gap(2),
                          Text('${task.durationMinutes}m',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary)),
                          if (task.dueDate != null) ...[
                            const Gap(8),
                            Icon(
                              Icons.event_rounded,
                              size: 11,
                              color: task.isOverdue
                                  ? AppColors.error
                                  : textSecondary,
                            ),
                            const Gap(2),
                            Text(
                              fmt.format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: task.isOverdue
                                    ? AppColors.error
                                    : textSecondary,
                                fontWeight: task.isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _catColor(String key) {
  switch (key) {
    case 'deen':
      return AppColors.deen;
    case 'learn':
      return AppColors.learn;
    case 'health':
      return AppColors.health;
    case 'work':
    case 'project':
      return AppColors.gold;
    case 'rest':
      return AppColors.textSecondary;
    default:
      return AppColors.learn;
  }
}

// ══════════════════════════════════════════════════════════════
// REUSED WIDGETS (Goals / Habits cards unchanged)
// ══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.textSecondary, required this.onAdd});
  final Color textSecondary;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.task_alt_rounded, size: 48, color: textSecondary),
            const Gap(12),
            Text('No tasks yet', style: TextStyle(color: textSecondary)),
            const Gap(4),
            Text('Add your first task below',
                style: TextStyle(color: textSecondary, fontSize: 12)),
            const Gap(16),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Task'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final active = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? active.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
              color: selected ? active : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label  $count',
          style: TextStyle(
            color: selected ? active : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: color),
      );
}

class _GoalTaskCard extends StatelessWidget {
  const _GoalTaskCard(
      {required this.goal, required this.textSecondary, required this.ref});
  final dynamic goal;
  final Color textSecondary;
  final WidgetRef ref;

  Color _priorityColor() {
    switch (goal.priority as String) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final daysLeft =
        (goal.targetDate as DateTime).difference(DateTime.now()).inDays;
    final overdue = daysLeft < 0;
    final progress = goal.progress as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (goal.priority as String).toUpperCase(),
                      style: TextStyle(
                          color: _priorityColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      goal.title as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Text(
                    overdue
                        ? '⚠️ ${-daysLeft}d overdue'
                        : fmt.format(goal.targetDate as DateTime),
                    style: TextStyle(
                        color: overdue ? AppColors.error : textSecondary,
                        fontSize: 12,
                        fontWeight:
                            overdue ? FontWeight.w600 : FontWeight.normal),
                  ),
                ],
              ),
              if ((goal.description as String?)?.isNotEmpty == true) ...[
                const Gap(6),
                Text(
                  goal.description as String,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 5,
                        backgroundColor:
                            AppColors.learn.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.learn),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Text('$progress%',
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontFamily: 'Roboto')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitTaskCard extends StatelessWidget {
  const _HabitTaskCard(
      {required this.habit, required this.textSecondary, required this.ref});
  final dynamic habit;
  final Color textSecondary;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDone = habit.isDoneToday as bool;
    final streak = habit.streak as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: isDone
            ? null
            : () => ref.read(habitsProvider.notifier).toggle(
                  habit.id as String,
                  DateFormat('yyyy-MM-dd').format(DateTime.now())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.health.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                      color:
                          isDone ? AppColors.health : AppColors.border,
                      width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.health)
                    : null,
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  habit.name as String,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isDone ? textSecondary : null),
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.health.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔥 $streak',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.health,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

