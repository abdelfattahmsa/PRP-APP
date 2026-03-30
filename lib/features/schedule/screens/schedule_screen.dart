import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../services/notification_service.dart';

const _uuid = Uuid();

// ── SCHEDULE SCREEN ──────────────────────────────────────────
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});
  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String _mode = 'normal';
  bool _alarmsOn = false;

  static const _modes = [
    ('normal',  '🏗️ Normal',  AppColors.gold),
    ('fasting', '🌙 Fasting', AppColors.fasting),
    ('friday',  '✨ Friday',  AppColors.deen),
    ('cairo',   '🏙️ Cairo',  AppColors.pmp),
  ];

  Color get _accent => _modes.firstWhere((m) => m.$1 == _mode).$3;

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(scheduleProvider(_mode));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          Row(children: [
            Icon(_alarmsOn ? Icons.notifications_active : Icons.notifications_off,
                size: 16, color: _alarmsOn ? AppColors.deen : AppColors.textSecondary),
            Switch(
              value: _alarmsOn,
              onChanged: (v) async {
                setState(() => _alarmsOn = v);
                if (v && blocksAsync.value != null) {
                  await NotificationService.instance
                      .scheduleBlockNotifications(blocksAsync.value!, 'Africa/Cairo');
                } else {
                  await NotificationService.instance.cancelAll();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('${Routes.schedule}/edit-block?mode=$_mode'),
            ),
          ]),
        ],
      ),
      body: Column(children: [
        // Mode tabs
        Container(
          height: 52, margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: _modes.map((m) {
            final active = m.$1 == _mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mode = m.$1),
                child: AnimatedContainer(
                  duration: 150.ms, margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: active ? m.$3.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: active ? m.$3.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Center(child: Text(m.$2, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? m.$3 : AppColors.textSecondary))),
                ),
              ),
            );
          }).toList()),
        ),
        Expanded(
          child: blocksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(child: Text('Unable to load schedule. Pull to retry.', style: const TextStyle(color: AppColors.error))),
            data: (blocks) => blocks.isEmpty
                ? _emptyState(context)
                : _BlocksList(blocks: blocks, mode: _mode, accent: _accent),
          ),
        ),
      ]),
    );
  }

  Widget _emptyState(BuildContext ctx) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.schedule_outlined, size: 48, color: _accent.withValues(alpha: 0.4)),
      const Gap(12),
      Text('No blocks for $_mode', style: const TextStyle(color: AppColors.textSecondary)),
      const Gap(16),
      ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add First Block'),
        onPressed: () => ctx.push('${Routes.schedule}/edit-block?mode=$_mode'),
      ),
    ]),
  );
}

class _BlocksList extends ConsumerWidget {
  const _BlocksList({required this.blocks, required this.mode, required this.accent});
  final List<ScheduleBlock> blocks;
  final String mode;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    int curIdx = -1;
    for (var i = 0; i < blocks.length - 1; i++) {
      if (nowMins >= blocks[i].minutesSinceMidnight && nowMins < blocks[i + 1].minutesSinceMidnight) { curIdx = i; break; }
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: blocks.length,
      onReorder: (o, n) {
        if (n > o) n--;
        final list = List<ScheduleBlock>.from(blocks);
        list.insert(n, list.removeAt(o));
        ScheduleActions.instance.reorder(ref, list, mode);
      },
      itemBuilder: (ctx, i) => _BlockTile(
        key: ValueKey(blocks[i].id),
        block: blocks[i], isCurrent: i == curIdx,
        isNext: i == curIdx + 1, mode: mode, index: i,
      ),
    );
  }
}

class _BlockTile extends ConsumerWidget {
  const _BlockTile({super.key, required this.block, required this.isCurrent, required this.isNext, required this.mode, required this.index});
  final ScheduleBlock block;
  final bool isCurrent, isNext;
  final String mode;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.categoryColor(block.categoryKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Dismissible(
        key: ValueKey('d_${block.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        confirmDismiss: (_) async => await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete block?'),
            content: Text('Remove "${block.label}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ),
        onDismissed: (_) => ScheduleActions.instance.deleteBlock(ref, block.id, mode),
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            color: isCurrent ? color.withValues(alpha: 0.12) : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isCurrent ? color.withValues(alpha: 0.4) : isNext ? color.withValues(alpha: 0.15) : AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push('${Routes.schedule}/edit-block?id=${block.id}&mode=$mode'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                SizedBox(width: 44, child: Text(block.time, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10.5, fontWeight: FontWeight.w600, color: color))),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)] : null)),
                const Gap(10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(block.label, style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400))),
                    if (isCurrent) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))),
                      child: Text('NOW', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 8, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ]),
                  if (block.note != null) ...[const Gap(2), Text(block.note!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic))],
                ])),
                if (block.duration != null) ...[
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
                    child: Text(block.duration!, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9, color: color)),
                  ),
                ],
                const Gap(8),
                Icon(Icons.drag_handle, size: 16, color: AppColors.textMuted),
              ]),
            ),
          ),
        ),
      ).animate(delay: (index * 25).ms).fadeIn(duration: 200.ms).slideX(begin: -0.05),
    );
  }
}

// ── EDIT BLOCK SCREEN ────────────────────────────────────────
class EditBlockScreen extends ConsumerStatefulWidget {
  const EditBlockScreen({super.key, this.blockId, required this.scheduleMode});
  final String? blockId;
  final String scheduleMode;
  @override
  ConsumerState<EditBlockScreen> createState() => _EditBlockState();
}

class _EditBlockState extends ConsumerState<EditBlockScreen> {
  final _label = TextEditingController();
  final _time  = TextEditingController();
  final _dur   = TextEditingController();
  final _note  = TextEditingController();
  String _cat  = 'work';
  bool _notifyS = true, _notifyE = false, _saving = false;
  ScheduleBlock? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.blockId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final blocks = ref.read(scheduleProvider(widget.scheduleMode)).value;
        if (blocks == null) return;
        final b = blocks.firstWhere((b) => b.id == widget.blockId, orElse: () => blocks.first);
        _existing = b;
        _label.text = b.label; _time.text = b.time;
        _dur.text = b.duration ?? ''; _note.text = b.note ?? '';
        setState(() { _cat = b.categoryKey; _notifyS = b.notifyOnStart; _notifyE = b.notifyOnEnd; });
      });
    } else { _time.text = '08:00'; }
  }

  @override
  void dispose() { _label.dispose(); _time.dispose(); _dur.dispose(); _note.dispose(); super.dispose(); }

  static final _timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  Future<void> _save() async {
    if (_label.text.isEmpty || _time.text.isEmpty) return;
    // Validate HH:MM format
    final timeStr = _time.text.trim();
    if (!_timeRegex.hasMatch(timeStr)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid time in HH:MM format (e.g. 04:55)'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final block = ScheduleBlock(
        id: _existing?.id ?? _uuid.v4(),
        scheduleMode: widget.scheduleMode,
        time: timeStr, label: _label.text.trim(),
        categoryKey: _cat,
        duration: _dur.text.trim().isEmpty ? null : _dur.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        order: _existing?.order ?? 99,
        notifyOnStart: _notifyS, notifyOnEnd: _notifyE,
      );
      if (_existing != null) {
        await ScheduleActions.instance.updateBlock(ref, block);
      } else {
        await ScheduleActions.instance.addBlock(ref, block);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save block. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blockId == null ? 'New Block' : 'Edit Block'),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)))
              : TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.gold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppTextField(controller: _label, label: 'Block Label', hint: 'e.g. Fajr + Morning Zekr'),
          const Gap(14),
          Row(children: [
            Expanded(child: AppTextField(controller: _time, label: 'Time (HH:MM)', hint: '04:55')),
            const Gap(12),
            Expanded(child: AppTextField(controller: _dur, label: 'Duration', hint: '30m or 1hr')),
          ]),
          const Gap(14),
          const Text('Category', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'IBMPlexMono', letterSpacing: 0.5)),
          const Gap(6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: AppConstants.categoryKeys.map((k) {
              final info = categoryInfoMap[k];
              final color = AppColors.categoryColor(k);
              final sel = _cat == k;
              return GestureDetector(
                onTap: () => setState(() => _cat = k),
                child: AnimatedContainer(
                  duration: 120.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: 0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? color.withValues(alpha: 0.5) : AppColors.border),
                  ),
                  child: Text('${info?.emoji ?? ''} ${info?.label ?? k}', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: sel ? color : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const Gap(14),
          AppTextField(controller: _note, label: 'Note (optional)', hint: 'Quick tip or reminder...', maxLines: 2),
          const Gap(14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Notify when block starts', style: TextStyle(fontSize: 13)),
                Switch(value: _notifyS, onChanged: (v) => setState(() => _notifyS = v)),
              ]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Notify when block ends', style: TextStyle(fontSize: 13)),
                Switch(value: _notifyE, onChanged: (v) => setState(() => _notifyE = v)),
              ]),
            ]),
          ),
          if (widget.blockId != null) ...[
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('Delete Block', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                onPressed: () async {
                  await ScheduleActions.instance.deleteBlock(ref, widget.blockId!, widget.scheduleMode);
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
