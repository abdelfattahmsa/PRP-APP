import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../engines/ideas/data/models/idea_models.dart';
import '../../engines/ideas/providers/ideas_providers.dart';
import '../../shared/models/all_providers.dart';
import '../../shared/widgets/bottom_sheets.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════
// QUICK CAPTURE FAB
// Speed-dial expandable FAB. 5 actions, visible on all tabs.
// ══════════════════════════════════════════════════════════════
class QuickCaptureFAB extends ConsumerStatefulWidget {
  const QuickCaptureFAB({super.key});

  @override
  ConsumerState<QuickCaptureFAB> createState() => _QuickCaptureFABState();
}

class _QuickCaptureFABState extends ConsumerState<QuickCaptureFAB> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);
  void _close() => setState(() => _expanded = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Action items (visible when expanded) ───────────────
        if (_expanded) ...[
          _FabAction(
            emoji: '💰',
            label: 'Add transaction',
            onTap: () {
              _close();
              showAddTransaction(context);
            },
          ),
          const SizedBox(height: 10),
          _FabAction(
            emoji: '✅',
            label: 'Log habit',
            onTap: () {
              _close();
              _showHabitQuickLog(context);
            },
          ),
          const SizedBox(height: 10),
          _FabAction(
            emoji: '⏱️',
            label: 'Start focus',
            onTap: () {
              _close();
              ref.read(focusTimerProvider.notifier).start();
              context.go(Routes.energyFocus);
            },
          ),
          const SizedBox(height: 10),
          _FabAction(
            emoji: '💡',
            label: 'Capture idea',
            onTap: () {
              _close();
              _showQuickIdeaCapture(context);
            },
          ),
          const SizedBox(height: 10),
          _FabAction(
            emoji: '➕',
            label: 'Add task / goal',
            onTap: () {
              _close();
              context.go(Routes.energyGoals);
            },
          ),
          const SizedBox(height: 14),
        ],

        // ── Main FAB ───────────────────────────────────────────
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: _expanded ? 6 : 4,
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  // ── Habit quick log ──────────────────────────────────────────
  void _showHabitQuickLog(BuildContext context) {
    final habits = ref.read(habitsProvider).asData?.value ?? [];
    final active = habits.where((h) => !h.isArchived).toList();

    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No habits yet — add one in Health → Habits')),
      );
      return;
    }

    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _HabitQuickLog(
        container: container,
        todayKey: _todayKey(),
      ),
    );
  }

  // ── Idea quick capture ──────────────────────────────────────
  void _showQuickIdeaCapture(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _QuickIdeaCapture(container: container),
    );
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════════
// FAB ACTION ITEM
// ══════════════════════════════════════════════════════════════
class _FabAction extends StatelessWidget {
  const _FabAction({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
  final String emoji, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HABIT QUICK LOG BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _HabitQuickLog extends StatelessWidget {
  const _HabitQuickLog({
    required this.container,
    required this.todayKey,
  });
  final ProviderContainer container;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (ctx, ref, _) {
          final habits =
              ref.watch(habitsProvider).asData?.value ?? [];
          final active =
              habits.where((h) => !h.isArchived).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Today's Habits",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final habit in active)
                ListTile(
                  leading: Text(habit.icon,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(habit.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary)),
                  trailing: habit.isDoneToday
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success)
                      : const Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: AppColors.textMuted),
                  onTap: () => ref
                      .read(habitsProvider.notifier)
                      .toggle(habit.id, todayKey),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// QUICK IDEA CAPTURE BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _QuickIdeaCapture extends StatefulWidget {
  const _QuickIdeaCapture({required this.container});
  final ProviderContainer container;

  @override
  State<_QuickIdeaCapture> createState() => _QuickIdeaCaptureState();
}

class _QuickIdeaCaptureState extends State<_QuickIdeaCapture> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: widget.container,
      child: Consumer(
        builder: (ctx, ref, _) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Capture Idea',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "What's the idea?",
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _save(ref, ctx),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          _saving ? null : () => _save(ref, ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black))
                          : const Text('Save idea 💡',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(WidgetRef ref, BuildContext ctx) async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final idea = Idea(
      id: _uuid.v4(),
      title: title,
      status: 'backlog',
      createdAt: DateTime.now(),
    );
    await ref.read(ideasProvider.notifier).add(idea);
    if (ctx.mounted) Navigator.of(ctx).pop();
  }
}
