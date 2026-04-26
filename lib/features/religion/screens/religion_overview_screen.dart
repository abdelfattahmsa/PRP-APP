import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../engines/religion/data/models/religion_models.dart';
import '../../../engines/religion/providers/religion_providers.dart';
import '../../../shared/widgets/placeholders.dart';

class ReligionOverviewScreen extends ConsumerWidget {
  const ReligionOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final todaySalahAsync = ref.watch(todaySalahProvider);
    final streak = ref.watch(salahStreakProvider);
    final quranMinutes = ref.watch(quranWeekMinutesProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Deen',
              subtitle: 'Your spiritual practice',
            ),
            const Gap(24),

            // ── Today's Salah Card ──────────────────────────────
            _SectionLabel(label: "Today's Salah", textSecondary: textSecondary),
            const Gap(10),
            GestureDetector(
              onTap: () => context.go(Routes.religionSalah),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: todaySalahAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Text('Error: $e', style: TextStyle(color: AppColors.error)),
                  data: (record) => _SalahRow(record: record, accent: accent, textSecondary: textSecondary),
                ),
              ),
            ),
            const Gap(16),

            // ── Stats row ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.warning,
                    label: 'Prayer Streak',
                    value: '$streak days',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: () => context.go(Routes.religionSalah),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.deen,
                    label: 'Quran This Week',
                    value: '$quranMinutes min',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: () => context.go(Routes.religionQuran),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // ── Quick Actions ───────────────────────────────────
            _SectionLabel(label: 'Tools', textSecondary: textSecondary),
            const Gap(10),
            SectionCard(children: [
              SettingsTile(
                leading: const Icon(Icons.calculate_outlined, size: 20),
                title: 'Zakat Calculator',
                subtitle: 'Check if Zakat is due on your wealth',
                onTap: () => context.go(Routes.religionZakat),
                trailing: Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                leading: const Icon(Icons.menu_book_outlined, size: 20),
                title: 'Quran Progress',
                subtitle: 'Log reading & memorization sessions',
                onTap: () => context.go(Routes.religionQuran),
                trailing: Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
              ),
            ]),

            const Gap(24),

            // ── Last 7 days mini calendar ───────────────────────
            _SectionLabel(label: 'Last 7 Days', textSecondary: textSecondary),
            const Gap(10),
            _SalahWeekRow(cardColor: cardColor, borderColor: borderColor, accent: accent),
          ],
        ),
      ),
    );
  }
}

// ── Salah row (5 prayer circles) ─────────────────────────────

class _SalahRow extends StatelessWidget {
  const _SalahRow({
    required this.record,
    required this.accent,
    required this.textSecondary,
  });
  final SalahRecord record;
  final Color accent;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final done = record.completedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$done/5 prayers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Gap(8),
            if (done == 5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.deen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Complete ✓',
                  style: TextStyle(fontSize: 11, color: AppColors.deen, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const Gap(14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: kPrayerKeys.map((key) {
            final isDone = record.prayers[key] == true;
            return _PrayerCircle(
              key: ValueKey(key),
              prayerKey: key,
              isDone: isDone,
              accent: accent,
              textSecondary: textSecondary,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PrayerCircle extends StatelessWidget {
  const _PrayerCircle({
    super.key,
    required this.prayerKey,
    required this.isDone,
    required this.accent,
    required this.textSecondary,
  });
  final String prayerKey;
  final bool isDone;
  final Color accent;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? accent.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isDone ? accent : textSecondary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              kPrayerEmojis[prayerKey] ?? '🕌',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const Gap(6),
        Text(
          kPrayerLabels[prayerKey] ?? prayerKey,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Roboto',
            fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
            color: isDone ? accent : textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Last-7-days row ──────────────────────────────────────────

class _SalahWeekRow extends ConsumerWidget {
  const _SalahWeekRow({
    required this.cardColor,
    required this.borderColor,
    required this.accent,
  });
  final Color cardColor;
  final Color borderColor;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(salahHistoryProvider);
    final history = historyAsync.asData?.value ?? [];
    final byDate = {for (final r in history) r.date: r};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final d = DateTime.now().subtract(Duration(days: 6 - i));
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final rec = byDate[key];
          final done = rec?.completedCount ?? 0;
          final isToday = i == 6;

          return Column(
            children: [
              Text(
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday % 7],
                style: TextStyle(
                  fontSize: 10,
                  color: isToday ? accent : AppColors.textSecondary,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: 'Roboto',
                ),
              ),
              const Gap(6),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done == 5
                          ? accent.withValues(alpha: 0.2)
                          : done > 0
                              ? accent.withValues(alpha: 0.07)
                              : Colors.transparent,
                      border: Border.all(
                        color: isToday
                            ? accent
                            : done > 0
                                ? accent.withValues(alpha: 0.3)
                                : borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  Text(
                    '$done',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: done > 0 ? accent : AppColors.textSecondary,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              const Gap(4),
              Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Small helpers ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.textSecondary});
  final String label;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textSecondary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
