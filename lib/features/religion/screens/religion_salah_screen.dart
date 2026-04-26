import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/religion/data/models/religion_models.dart';
import '../../../engines/religion/providers/religion_providers.dart';
import '../../../shared/widgets/placeholders.dart';

class ReligionSalahScreen extends ConsumerWidget {
  const ReligionSalahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final todaySalahAsync = ref.watch(todaySalahProvider);
    final streak = ref.watch(salahStreakProvider);
    final historyAsync = ref.watch(salahHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Salah',
              subtitle: 'Daily prayer tracker',
            ),
            const Gap(24),

            // ── Streak banner ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.deen.withValues(alpha: 0.15),
                    AppColors.deen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak day streak',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.deen,
                            ),
                      ),
                      Text(
                        streak == 0
                            ? 'Start your streak today'
                            : streak == 1
                                ? 'Keep going — one day at a time'
                                : 'Consecutive full-prayer days',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(24),

            // ── Today's prayers ─────────────────────────────────
            SectionHeader("Today's Prayers"),
            const Gap(12),
            todaySalahAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              data: (record) => Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: kPrayerKeys.asMap().entries.map((entry) {
                    final i = entry.key;
                    final key = entry.value;
                    final isDone = record.prayers[key] == true;
                    return Column(
                      children: [
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _PrayerTile(
                          prayerKey: key,
                          isDone: isDone,
                          accent: accent,
                          textSecondary: textSecondary,
                          onToggle: () =>
                              ref.read(todaySalahProvider.notifier).togglePrayer(key),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const Gap(24),

            // ── 30-day history ──────────────────────────────────
            const SectionHeader('Last 30 Days'),
            const Gap(12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const SizedBox.shrink(),
              data: (history) => _SalahCalendar(
                history: history,
                accent: accent,
                cardColor: cardColor,
                borderColor: borderColor,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prayer tile ───────────────────────────────────────────────

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.prayerKey,
    required this.isDone,
    required this.accent,
    required this.textSecondary,
    required this.onToggle,
  });
  final String prayerKey;
  final bool isDone;
  final Color accent;
  final Color textSecondary;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              kPrayerEmojis[prayerKey] ?? '🕌',
              style: const TextStyle(fontSize: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kPrayerLabels[prayerKey] ?? prayerKey,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDone ? null : textSecondary,
                        ),
                  ),
                  Text(
                    _prayerTimeHint(prayerKey),
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? accent : Colors.transparent,
                border: Border.all(
                  color: isDone ? accent : textSecondary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _prayerTimeHint(String key) {
    return switch (key) {
      'fajr'    => 'Before sunrise',
      'dhuhr'   => 'After midday',
      'asr'     => 'Afternoon',
      'maghrib' => 'After sunset',
      'isha'    => 'Night',
      _         => '',
    };
  }
}

// ── 30-day salah calendar ────────────────────────────────────

class _SalahCalendar extends StatelessWidget {
  const _SalahCalendar({
    required this.history,
    required this.accent,
    required this.cardColor,
    required this.borderColor,
    required this.textSecondary,
  });
  final List<SalahRecord> history;
  final Color accent;
  final Color cardColor;
  final Color borderColor;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final byDate = {for (final r in history) r.date: r};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            children: [
              _LegendDot(color: accent, label: '5 prayers', accent: accent),
              const Gap(12),
              _LegendDot(color: accent.withValues(alpha: 0.4), label: '1–4', accent: accent),
              const Gap(12),
              _LegendDot(color: borderColor, label: 'None logged', accent: accent),
            ],
          ),
          const Gap(12),
          // Grid: 30 days, 7 per row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(30, (i) {
              final d = DateTime.now().subtract(Duration(days: 29 - i));
              final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              final rec = byDate[key];
              final done = rec?.completedCount ?? 0;
              final isToday = i == 29;

              Color fill;
              if (done == 5) {
                fill = accent.withValues(alpha: 0.3);
              } else if (done > 0) {
                fill = accent.withValues(alpha: 0.1 + (done / 5) * 0.15);
              } else {
                fill = Colors.transparent;
              }

              return Tooltip(
                message: '${d.day}/${d.month}: $done/5 prayers',
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isToday ? accent : borderColor,
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$done',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: done > 0 ? accent : textSecondary,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.accent});
  final Color color;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const Gap(4),
        Text(label,
            style: const TextStyle(fontSize: 10, fontFamily: 'Roboto')),
      ],
    );
  }
}
