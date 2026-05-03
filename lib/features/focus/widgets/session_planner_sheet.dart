import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/all_providers.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════
// SHOW HELPER
// ══════════════════════════════════════════════════════════════

Future<void> showSessionPlannerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const _SessionPlannerSheet(),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// SHEET WIDGET
// ══════════════════════════════════════════════════════════════

class _SessionPlannerSheet extends ConsumerStatefulWidget {
  const _SessionPlannerSheet();

  @override
  ConsumerState<_SessionPlannerSheet> createState() =>
      _SessionPlannerSheetState();
}

class _SessionPlannerSheetState extends ConsumerState<_SessionPlannerSheet> {
  // Working list of planned sessions
  final List<PlannedSession> _sessions = [];

  // Settings
  bool _autoAdvance = true;
  int _shortBreak = 5;
  int _longBreak = 15;
  int _sessionsBefore = 4;

  // Free-form session add
  final _customLabelCtrl = TextEditingController();
  String _customCategoryKey = 'work';
  int _customDuration = 25;
  bool _addingCustom = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate from existing queue if any
    final existing = ref.read(focusQueueProvider);
    if (existing.sessions.isNotEmpty) {
      _sessions.addAll(existing.sessions);
      _autoAdvance = existing.autoAdvance;
      _shortBreak = existing.shortBreakMinutes;
      _longBreak = existing.longBreakMinutes;
      _sessionsBefore = existing.sessionsBeforeLongBreak;
    }
  }

  @override
  void dispose() {
    _customLabelCtrl.dispose();
    super.dispose();
  }

  void _addTask(UserTask task) {
    setState(() {
      _sessions.add(PlannedSession(
        id: _uuid.v4(),
        label: task.title,
        categoryKey: task.categoryKey,
        taskId: task.id,
        durationMinutes: task.durationMinutes,
      ));
    });
  }

  void _addCustomSession() {
    final label = _customLabelCtrl.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _sessions.add(PlannedSession(
        id: _uuid.v4(),
        label: label,
        categoryKey: _customCategoryKey,
        durationMinutes: _customDuration,
      ));
      _customLabelCtrl.clear();
      _addingCustom = false;
    });
  }

  void _removeSession(int index) {
    setState(() => _sessions.removeAt(index));
  }

  void _updateDuration(int index, int minutes) {
    setState(() {
      _sessions[index] = _sessions[index].copyWith(durationMinutes: minutes);
    });
  }

  void _startPlan() {
    if (_sessions.isEmpty) return;
    ref.read(focusQueueProvider.notifier).loadPlan(
          _sessions,
          autoAdvance: _autoAdvance,
          shortBreakMinutes: _shortBreak,
          longBreakMinutes: _longBreak,
          sessionsBeforeLongBreak: _sessionsBefore,
        );
    Navigator.of(context).pop();
  }

  int get _totalMinutes =>
      _sessions.fold(0, (s, sess) => s + sess.durationMinutes) +
      (_sessions.isEmpty ? 0 : _sessions.length - 1) * _shortBreak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final tasksAsync = ref.watch(tasksProvider);
    final openTasks = (tasksAsync.value ?? []).where((t) => !t.completed).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan Your Session',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (_sessions.isNotEmpty)
                          Text(
                            '${_sessions.length} focus block${_sessions.length == 1 ? '' : 's'}  •  ~${_totalMinutes}m total',
                            style: TextStyle(
                                fontSize: 12, color: accent),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (_sessions.isNotEmpty)
                      FilledButton.icon(
                        onPressed: _startPlan,
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Start'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    const Gap(8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    // ── Planned Queue ──────────────────────────────
                    if (_sessions.isNotEmpty) ...[
                      _SectionLabel('📋 Session Queue', textSecondary),
                      const Gap(8),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessions.length,
                        onReorder: (o, n) {
                          setState(() {
                            if (n > o) n--;
                            final item = _sessions.removeAt(o);
                            _sessions.insert(n, item);
                          });
                        },
                        itemBuilder: (ctx, i) {
                          final s = _sessions[i];
                          final isLong =
                              (i + 1) % _sessionsBefore == 0 &&
                                  i < _sessions.length - 1;
                          return _QueueItem(
                            key: ValueKey(s.id),
                            session: s,
                            index: i,
                            total: _sessions.length,
                            isLongBreakAfter: isLong,
                            shortBreak: _shortBreak,
                            longBreak: _longBreak,
                            textSecondary: textSecondary,
                            accent: accent,
                            onDurationChanged: (v) => _updateDuration(i, v),
                            onRemove: () => _removeSession(i),
                          );
                        },
                      ),
                      const Gap(16),
                    ],

                    // ── Add from Tasks ─────────────────────────────
                    if (openTasks.isNotEmpty) ...[
                      _SectionLabel('📌 Add from Your Tasks', textSecondary),
                      const Gap(8),
                      ...openTasks.map((t) => _TaskPickerTile(
                            task: t,
                            alreadyAdded: _sessions
                                .any((s) => s.taskId == t.id),
                            accent: accent,
                            textSecondary: textSecondary,
                            onAdd: () => _addTask(t),
                          )),
                      const Gap(16),
                    ],

                    // ── Add Custom Block ───────────────────────────
                    _SectionLabel('➕ Add Custom Block', textSecondary),
                    const Gap(8),
                    if (!_addingCustom)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _addingCustom = true),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Custom focus block'),
                      )
                    else
                      _CustomBlockForm(
                        ctrl: _customLabelCtrl,
                        categoryKey: _customCategoryKey,
                        duration: _customDuration,
                        border: border,
                        accent: accent,
                        onCategoryChanged: (v) =>
                            setState(() => _customCategoryKey = v),
                        onDurationChanged: (v) =>
                            setState(() => _customDuration = v),
                        onAdd: _addCustomSession,
                        onCancel: () =>
                            setState(() => _addingCustom = false),
                      ),

                    const Gap(24),

                    // ── Break Settings ─────────────────────────────
                    _SectionLabel('⏱ Break Settings', textSecondary),
                    const Gap(8),
                    _BreakSettings(
                      shortBreak: _shortBreak,
                      longBreak: _longBreak,
                      sessionsBefore: _sessionsBefore,
                      autoAdvance: _autoAdvance,
                      border: border,
                      accent: accent,
                      textSecondary: textSecondary,
                      onShortBreakChanged: (v) =>
                          setState(() => _shortBreak = v),
                      onLongBreakChanged: (v) =>
                          setState(() => _longBreak = v),
                      onSessionsBeforeChanged: (v) =>
                          setState(() => _sessionsBefore = v),
                      onAutoAdvanceChanged: (v) =>
                          setState(() => _autoAdvance = v),
                    ),

                    const Gap(24),

                    // Start button (also at bottom)
                    if (_sessions.isNotEmpty)
                      FilledButton.icon(
                        onPressed: _startPlan,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                            'Start ${_sessions.length} Session${_sessions.length == 1 ? '' : 's'}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// QUEUE ITEM WIDGET
// ══════════════════════════════════════════════════════════════

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    super.key,
    required this.session,
    required this.index,
    required this.total,
    required this.isLongBreakAfter,
    required this.shortBreak,
    required this.longBreak,
    required this.textSecondary,
    required this.accent,
    required this.onDurationChanged,
    required this.onRemove,
  });
  final PlannedSession session;
  final int index;
  final int total;
  final bool isLongBreakAfter;
  final int shortBreak;
  final int longBreak;
  final Color textSecondary;
  final Color accent;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final info = categoryInfoMap[session.categoryKey];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Drag handle
              Icon(Icons.drag_indicator_rounded, size: 18, color: textSecondary),
              const Gap(8),
              // Index badge
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ),
              ),
              const Gap(8),
              Text(info?.emoji ?? '📌', style: const TextStyle(fontSize: 14)),
              const Gap(6),
              Expanded(
                child: Text(
                  session.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Duration stepper
              _MiniStepper(
                value: session.durationMinutes,
                min: 5,
                max: 120,
                step: 5,
                accent: accent,
                textSecondary: textSecondary,
                onChanged: onDurationChanged,
              ),
              const Gap(8),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        // Break indicator
        if (index < total - 1)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.coffee_outlined, size: 12, color: textSecondary),
                const Gap(4),
                Text(
                  isLongBreakAfter
                      ? '🧘 Long break — ${longBreak}m'
                      : '☕ Short break — ${shortBreak}m',
                  style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MINI DURATION STEPPER
// ══════════════════════════════════════════════════════════════

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.accent,
    required this.textSecondary,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final int step;
  final Color accent;
  final Color textSecondary;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > min ? () => onChanged(value - step) : null,
          child: Icon(Icons.remove_circle_outline_rounded,
              size: 18,
              color: value > min ? accent : textSecondary),
        ),
        const Gap(4),
        SizedBox(
          width: 38,
          child: Text('${value}m',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const Gap(4),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + step) : null,
          child: Icon(Icons.add_circle_outline_rounded,
              size: 18,
              color: value < max ? accent : textSecondary),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TASK PICKER TILE
// ══════════════════════════════════════════════════════════════

class _TaskPickerTile extends StatelessWidget {
  const _TaskPickerTile({
    required this.task,
    required this.alreadyAdded,
    required this.accent,
    required this.textSecondary,
    required this.onAdd,
  });
  final UserTask task;
  final bool alreadyAdded;
  final Color accent;
  final Color textSecondary;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final info = categoryInfoMap[task.categoryKey];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: alreadyAdded
                        ? accent.withValues(alpha: 0.4)
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppColors.border
                            : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Text(info?.emoji ?? '📌',
                      style: const TextStyle(fontSize: 14)),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${task.durationMinutes}m · ${info?.label ?? task.categoryKey}',
                            style: TextStyle(
                                fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: alreadyAdded
                ? Icon(Icons.check_circle_rounded,
                    color: accent, size: 28, key: const ValueKey('added'))
                : IconButton(
                    key: const ValueKey('add'),
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                    color: accent,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM BLOCK FORM
// ══════════════════════════════════════════════════════════════

class _CustomBlockForm extends StatelessWidget {
  const _CustomBlockForm({
    required this.ctrl,
    required this.categoryKey,
    required this.duration,
    required this.border,
    required this.accent,
    required this.onCategoryChanged,
    required this.onDurationChanged,
    required this.onAdd,
    required this.onCancel,
  });
  final TextEditingController ctrl;
  final String categoryKey;
  final int duration;
  final Color border;
  final Color accent;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondary
        : AppColors.lightTextSecondary;
    final cats = AppConstants.categoryKeys
        .map((k) => DropdownMenuItem(
              value: k,
              child: Text(
                  '${categoryInfoMap[k]?.emoji ?? '📌'} ${categoryInfoMap[k]?.label ?? k}'),
            ))
        .toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Block label (e.g. Deep work)',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const Gap(8),
            SizedBox(
              width: 80,
              child: _MiniStepper(
                value: duration,
                min: 5,
                max: 120,
                step: 5,
                accent: accent,
                textSecondary: textSecondary,
                onChanged: onDurationChanged,
              ),
            ),
          ],
        ),
        const Gap(8),
        DropdownButtonFormField<String>(
          initialValue: categoryKey,
          decoration: InputDecoration(
            labelText: 'Category',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: cats,
          onChanged: (v) => onCategoryChanged(v!),
        ),
        const Gap(8),
        Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
            const Gap(8),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Block'),
              style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10)),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BREAK SETTINGS WIDGET
// ══════════════════════════════════════════════════════════════

class _BreakSettings extends StatelessWidget {
  const _BreakSettings({
    required this.shortBreak,
    required this.longBreak,
    required this.sessionsBefore,
    required this.autoAdvance,
    required this.border,
    required this.accent,
    required this.textSecondary,
    required this.onShortBreakChanged,
    required this.onLongBreakChanged,
    required this.onSessionsBeforeChanged,
    required this.onAutoAdvanceChanged,
  });
  final int shortBreak;
  final int longBreak;
  final int sessionsBefore;
  final bool autoAdvance;
  final Color border;
  final Color accent;
  final Color textSecondary;
  final ValueChanged<int> onShortBreakChanged;
  final ValueChanged<int> onLongBreakChanged;
  final ValueChanged<int> onSessionsBeforeChanged;
  final ValueChanged<bool> onAutoAdvanceChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _BreakRow(
            icon: Icons.coffee_outlined,
            label: 'Short break',
            value: shortBreak,
            min: 1,
            max: 30,
            accent: accent,
            textSecondary: textSecondary,
            onChanged: onShortBreakChanged,
          ),
          const Gap(8),
          _BreakRow(
            icon: Icons.self_improvement_rounded,
            label: 'Long break',
            value: longBreak,
            min: 5,
            max: 60,
            accent: accent,
            textSecondary: textSecondary,
            onChanged: onLongBreakChanged,
          ),
          const Gap(8),
          _BreakRow(
            icon: Icons.repeat_rounded,
            label: 'Sessions before long break',
            value: sessionsBefore,
            min: 2,
            max: 8,
            step: 1,
            accent: accent,
            textSecondary: textSecondary,
            onChanged: onSessionsBeforeChanged,
          ),
          const Gap(8),
          Row(
            children: [
              Icon(Icons.play_arrow_rounded, size: 18, color: textSecondary),
              const Gap(8),
              Expanded(
                child: Text('Auto-start next session',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
              ),
              Switch(
                value: autoAdvance,
                onChanged: onAutoAdvanceChanged,
                activeThumbColor: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakRow extends StatelessWidget {
  const _BreakRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.textSecondary,
    required this.onChanged,
    this.step = 1,
  });
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final Color accent;
  final Color textSecondary;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const Gap(8),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: textSecondary)),
        ),
        _MiniStepper(
          value: value,
          min: min,
          max: max,
          step: step,
          accent: accent,
          textSecondary: textSecondary,
          onChanged: onChanged,
        ),
        if (label.contains('break'))
          Text('m',
              style: TextStyle(fontSize: 12, color: textSecondary)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION LABEL
// ══════════════════════════════════════════════════════════════

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
