// ======================================================================
// ENERGY MOOD SCREEN  — daily morning + evening mood tracker
// ======================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/all_providers.dart';

class EnergyMoodScreen extends ConsumerWidget {
  const EnergyMoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodAsync = ref.watch(moodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood')),
      body: moodAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Could not load mood data',
                style: const TextStyle(color: AppColors.error))),
        data: (entries) {
          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          MoodEntry? todayMorning = entries.where((e) {
            final d = e.timestamp;
            final ds =
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            return ds == todayStr && e.period == 'morning';
          }).firstOrNull;

          MoodEntry? todayEvening = entries.where((e) {
            final d = e.timestamp;
            final ds =
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            return ds == todayStr && e.period == 'evening';
          }).firstOrNull;

          // history — skip today
          final history = entries
              .where((e) {
                final d = e.timestamp;
                final ds =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                return ds != todayStr;
              })
              .take(30)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ── Today ───────────────────────────────────────
              _SectionHeader("Today · ${DateFormat('EEEE, d MMM').format(today)}"),
              const Gap(12),
              Row(children: [
                Expanded(
                  child: _MoodCheckInCard(
                    period: 'morning',
                    label: 'Morning',
                    icon: '🌅',
                    current: todayMorning,
                    ref: ref,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _MoodCheckInCard(
                    period: 'evening',
                    label: 'Evening',
                    icon: '🌙',
                    current: todayEvening,
                    ref: ref,
                  ),
                ),
              ]),
              const Gap(24),

              // ── 7-day overview ───────────────────────────────
              _MoodWeekChart(entries: entries),
              const Gap(24),

              // ── History ─────────────────────────────────────
              if (history.isNotEmpty) ...[
                _SectionHeader('History'),
                const Gap(10),
                ...history.map((e) => _MoodHistoryTile(entry: e, ref: ref)),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          color: AppColors.gold,
          letterSpacing: 1.5,
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// CHECK-IN CARD (morning / evening)
// ══════════════════════════════════════════════════════════════
class _MoodCheckInCard extends ConsumerStatefulWidget {
  const _MoodCheckInCard({
    required this.period,
    required this.label,
    required this.icon,
    required this.current,
    required this.ref,
  });

  final String period;
  final String label;
  final String icon;
  final MoodEntry? current;
  final WidgetRef ref;

  @override
  ConsumerState<_MoodCheckInCard> createState() => _MoodCheckInCardState();
}

class _MoodCheckInCardState extends ConsumerState<_MoodCheckInCard> {
  int? _hoveredLevel;

  // Delegate to MoodEntry statics for single source of truth
  static List<String> get _emojis      => MoodEntry.emojis;
  static List<String> get _labels      => MoodEntry.labels;
  static List<int>    get _colorValues => MoodEntry.colors;

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final selectedLevel = current?.level;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedLevel != null
              ? Color(_colorValues[selectedLevel - 1]).withValues(alpha: 0.4)
              : (isDark ? AppColors.border : AppColors.lightBorder),
        ),
      ),
      child: Column(children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.icon, style: const TextStyle(fontSize: 18)),
          const Gap(6),
          Text(
            widget.label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto'),
          ),
        ]),
        const Gap(12),

        // Current mood display or prompt
        if (selectedLevel != null) ...[
          Text(
            _emojis[selectedLevel - 1],
            style: const TextStyle(fontSize: 32),
          ).animate().scale(duration: 200.ms),
          const Gap(4),
          Text(
            _labels[selectedLevel - 1],
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              color: Color(_colorValues[selectedLevel - 1]),
            ),
          ),
          const Gap(8),
        ] else ...[
          const Text(
            'How are you?',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'Roboto'),
          ),
          const Gap(10),
        ],

        // Emoji selector row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final level = i + 1;
            final isSelected = selectedLevel == level;
            final isHovered = _hoveredLevel == level;
            return GestureDetector(
              onTap: () => _logMood(level),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredLevel = level),
                onExit: (_) => setState(() => _hoveredLevel = null),
                child: AnimatedContainer(
                  duration: 150.ms,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected || isHovered
                        ? Color(_colorValues[i]).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Color(_colorValues[i])
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _emojis[i],
                      style: TextStyle(
                          fontSize: isSelected || isHovered ? 20 : 16),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Future<void> _logMood(int level) async {
    final noteCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${MoodEntry.emojis[level - 1]} ${MoodEntry.labels[level - 1]}'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add a note (optional)…',
            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          autofocus: false,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && mounted) {
      await ref.read(moodProvider.notifier).logToday(
            period: widget.period,
            level: level,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
    }
    noteCtrl.dispose();
  }
}

// ══════════════════════════════════════════════════════════════
// 7-DAY MOOD CHART
// ══════════════════════════════════════════════════════════════
class _MoodWeekChart extends StatelessWidget {
  const _MoodWeekChart({required this.entries});
  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final days =
        List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.border : AppColors.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeader('LAST 7 DAYS'),
        const Gap(14),
        Row(
          children: days.map((day) {
            final ds =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final morning = entries.where((e) {
              final d = e.timestamp;
              final s =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              return s == ds && e.period == 'morning';
            }).firstOrNull;
            final evening = entries.where((e) {
              final d = e.timestamp;
              final s =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              return s == ds && e.period == 'evening';
            }).firstOrNull;

            return Expanded(
              child: Column(children: [
                // Evening dot
                _MoodDot(entry: evening, small: true),
                const Gap(3),
                // Morning dot
                _MoodDot(entry: morning, small: false),
                const Gap(5),
                Text(
                  DateFormat('EEE').format(day).substring(0, 1),
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontFamily: 'Roboto'),
                ),
                Text(
                  '${day.day}',
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontFamily: 'Roboto'),
                ),
              ]),
            );
          }).toList(),
        ),
        const Gap(10),
        Row(children: [
          _LegendDot(label: 'Morning', color: AppColors.gold),
          const Gap(14),
          _LegendDot(label: 'Evening', color: AppColors.deen),
        ]),
      ]),
    );
  }
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.entry, required this.small});
  final MoodEntry? entry;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 14.0 : 18.0;
    if (entry == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      );
    }
    return Tooltip(
      message: '${entry!.emoji} ${entry!.label}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color(entry!.colorValue),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(entry!.emoji, style: TextStyle(fontSize: size * 0.65)),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const Gap(5),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary, fontFamily: 'Roboto')),
        ],
      );
}

// ══════════════════════════════════════════════════════════════
// HISTORY TILE
// ══════════════════════════════════════════════════════════════
class _MoodHistoryTile extends ConsumerWidget {
  const _MoodHistoryTile({required this.entry, required this.ref});
  final MoodEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(entry.id),
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
          title: const Text('Delete mood entry?'),
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
      ),
      onDismissed: (_) => ref.read(moodProvider.notifier).delete(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.lightCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark ? AppColors.border : AppColors.lightBorder),
        ),
        child: Row(children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 22)),
          const Gap(12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(entry.colorValue),
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const Gap(2),
                    Text(
                      entry.note!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              DateFormat('d MMM').format(entry.timestamp),
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'Roboto'),
            ),
            const Gap(2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (entry.period == 'morning'
                        ? AppColors.gold
                        : AppColors.deen)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.period == 'morning' ? '🌅' : '🌙',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
