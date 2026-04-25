import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/ideas/data/models/idea_models.dart';
import '../../../engines/ideas/providers/ideas_providers.dart';
import '../../../shared/widgets/app_card.dart' show AppCard;
import '../../../shared/widgets/app_states.dart' show EmptyState, ErrorState;
import '../../../shared/widgets/app_text_field.dart' show AppTextField;

const _uuid = Uuid();

const _statusLabels = {
  'backlog': 'Backlog',
  'thinking': 'Thinking',
  'active': 'Active',
  'done': 'Done',
};

const _statusColors = {
  'backlog': AppColors.textSecondary,
  'thinking': AppColors.warning,
  'active': AppColors.accent,
  'done': AppColors.success,
};

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  String _filter = 'all';

  void _showAddDialog() {
    showDialog(context: context, builder: (_) => const _AddIdeaDialog());
  }

  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(ideasProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ideas',
                            style:
                                Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    )),
                        Text('Capture & track your ideas',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.lightTextSecondary,
                                )),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Idea'),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                  ),
                ],
              ),
            ),
            const Gap(16),
            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  const Gap(8),
                  for (final s in _statusLabels.keys) ...[
                    _FilterChip(
                        label: _statusLabels[s]!,
                        selected: _filter == s,
                        color: _statusColors[s],
                        onTap: () => setState(() => _filter = s)),
                    const Gap(8),
                  ],
                ],
              ),
            ),
            const Gap(12),
            Expanded(
              child: ideasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const ErrorState(message: 'Could not load ideas'),
                data: (ideas) {
                  final filtered = _filter == 'all'
                      ? ideas
                      : ideas.where((i) => i.status == _filter).toList();
                  if (filtered.isEmpty) {
                    return EmptyState(
                      message: _filter == 'all'
                          ? 'No ideas yet — add your first one'
                          : 'No ideas in "${_statusLabels[_filter]}"',
                      icon: Icons.lightbulb_outline,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (_, i) =>
                        _IdeaCard(idea: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Idea Card ──────────────────────────────────────────────────

class _IdeaCard extends ConsumerWidget {
  const _IdeaCard({required this.idea});
  final Idea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColors[idea.status] ?? AppColors.textSecondary;

    return AppCard(
      padding: const EdgeInsets.all(Spacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (idea.description?.isNotEmpty == true) ...[
                  const Gap(4),
                  Text(
                    idea.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabels[idea.status] ?? idea.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 18,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary),
            onSelected: (v) {
              if (v == 'delete') {
                ref.read(ideasProvider.notifier).delete(idea.id);
              } else {
                ref.read(ideasProvider.notifier).setStatus(idea.id, v);
              }
            },
            itemBuilder: (_) => [
              for (final s in _statusLabels.entries)
                if (s.key != idea.status)
                  PopupMenuItem(
                    value: s.key,
                    child: Text('Move to ${s.value}'),
                  ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add Idea Dialog ────────────────────────────────────────────

class _AddIdeaDialog extends ConsumerStatefulWidget {
  const _AddIdeaDialog();

  @override
  ConsumerState<_AddIdeaDialog> createState() => _AddIdeaDialogState();
}

class _AddIdeaDialogState extends ConsumerState<_AddIdeaDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'backlog';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final idea = Idea(
      id: _uuid.v4(),
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      status: _status,
      createdAt: DateTime.now(),
    );
    ref.read(ideasProvider.notifier).add(idea);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Idea'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _titleCtrl,
              label: 'Title',
              hint: 'What\'s the idea?',
            ),
            const Gap(12),
            AppTextField(
              controller: _descCtrl,
              label: 'Description (optional)',
              hint: 'More details...',
              maxLines: 3,
            ),
            const Gap(12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statusLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
