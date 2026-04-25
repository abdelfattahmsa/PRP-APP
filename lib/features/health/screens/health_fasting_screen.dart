import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader, SectionHeader;

class HealthFastingScreen extends ConsumerWidget {
  const HealthFastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingProvider);
    ref.watch(fastingTickProvider); // drive re-builds every second

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Fasting',
              subtitle: 'Track your intermittent fasting window',
            ),
            const Gap(24),

            // ── Active / Start card ──────────────────────────────
            _FastTimerCard(
                fasting: fasting,
                accent: accent,
                textSecondary: textSecondary),
            const Gap(24),

            // ── Stats ────────────────────────────────────────────
            SectionHeader('Stats'),
            const Gap(12),
            BentoGrid(
              children: [
                BentoCell(
                  child: KpiCard(
                    label: 'Streak',
                    value: '${fasting.currentStreak}d',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.error,
                    subtitle: fasting.currentStreak > 0
                        ? 'Keep going!'
                        : 'Start fasting',
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Avg Window',
                    value: _fmtDur(fasting.avgWindow),
                    icon: Icons.hourglass_bottom_rounded,
                    iconColor: accent,
                    subtitle:
                        '${fasting.history.where((r) => r.isComplete).length} sessions',
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Best Fast',
                    value:
                        _fmtDur(fasting.longestFast?.duration ?? Duration.zero),
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.gold,
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Protocol',
                    value: '${fasting.goalHours}:${24 - fasting.goalHours}',
                    icon: Icons.schedule_rounded,
                    iconColor: textSecondary,
                  ),
                ),
              ],
            ),
            const Gap(24),

            // ── Protocol selector (only when not fasting) ────────
            if (!fasting.isFasting) ...[
              SectionHeader('Choose Protocol'),
              const Gap(12),
              _ProtocolSelector(current: fasting.goalHours),
              const Gap(24),
            ],

            // ── History ──────────────────────────────────────────
            if (fasting.history.isNotEmpty) ...[
              SectionHeader('Recent Fasts'),
              const Gap(12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0;
                        i <
                            fasting.history.reversed
                                .take(8)
                                .toList()
                                .length;
                        i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.border
                              : AppColors.lightBorder,
                        ),
                      _FastHistoryTile(
                        record:
                            fasting.history.reversed.toList()[i],
                        textSecondary: textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (!fasting.isFasting)
              EmptyState(
                message:
                    'No fasting history yet — start your first fast!',
                icon: Icons.hourglass_empty_rounded,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtDur(Duration d) {
    if (d == Duration.zero) return '—';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ──────────────────────────────────────────────────────────────
// Fast Timer Card
// ──────────────────────────────────────────────────────────────

class _FastTimerCard extends ConsumerWidget {
  const _FastTimerCard({
    required this.fasting,
    required this.accent,
    required this.textSecondary,
  });
  final FastingState fasting;
  final Color accent;
  final Color textSecondary;

  static String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        children: [
          Text(
            fasting.isFasting ? 'Currently Fasting' : 'Not Fasting',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: fasting.isFasting ? accent : textSecondary,
                  letterSpacing: 1.0,
                  ),
          ),
          const Gap(16),
          Text(
            fasting.isFasting ? _fmt(fasting.elapsed) : '00:00:00',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: fasting.isFasting ? accent : textSecondary,
              letterSpacing: -1,
            ),
          ),
          if (fasting.isFasting) ...[
            const Gap(8),
            Text(
              'Goal: ${fasting.active!.goalHours}:${24 - fasting.active!.goalHours} · '
              '${_fmt(fasting.remaining)} remaining',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textSecondary),
            ),
            const Gap(16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fasting.progress,
                backgroundColor: accent.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 8,
              ),
            ),
            const Gap(4),
            Text(
              '${fasting.active!.goalHours}h goal · Started '
              '${DateFormat('HH:mm').format(fasting.active!.startTime)}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: textSecondary),
            ),
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(fastingProvider.notifier).stopFast(),
                    child: const Text('Stop Fast'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        ref.read(fastingProvider.notifier).extendFast(1),
                    child: const Text('Extend +1h'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(fastingProvider.notifier).startFast(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Fast'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Protocol Selector
// ──────────────────────────────────────────────────────────────

class _ProtocolSelector extends ConsumerWidget {
  const _ProtocolSelector({required this.current});
  final int current;

  static const _protocols = [14, 16, 18, 20, 24];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Row(
      children: _protocols.map((h) {
        final selected = h == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () =>
                  ref.read(fastingProvider.notifier).setGoal(h),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? accent : borderColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$h:${24 - h}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : null,
                      ),
                    ),
                    Text(
                      '${h}h fast',
                      style: TextStyle(
                        fontSize: 9,
                        color: selected
                            ? accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// History Tile
// ──────────────────────────────────────────────────────────────

class _FastHistoryTile extends StatelessWidget {
  const _FastHistoryTile(
      {required this.record, required this.textSecondary});
  final FastRecord record;
  final Color textSecondary;

  static String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final reached = record.goalReached;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: 10),
      child: Row(
        children: [
          Icon(
            reached
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: reached ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, d MMM').format(record.startTime),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Started ${DateFormat('HH:mm').format(record.startTime)}'
                  '${record.endTime != null ? ' · Ended ${DateFormat('HH:mm').format(record.endTime!)}' : ''}',
                  style: TextStyle(
                      fontSize: 11,
                      color: textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtDur(record.duration),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: reached ? AppColors.success : textSecondary,
                ),
              ),
              Text(
                '${record.goalHours}h goal',
                style: TextStyle(
                    fontSize: 10,
                    color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
