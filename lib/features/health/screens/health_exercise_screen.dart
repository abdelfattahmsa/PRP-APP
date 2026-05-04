import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/data/models/health_models.dart';
import '../../../engines/health/providers/health_providers.dart';

class HealthExerciseScreen extends ConsumerWidget {
  const HealthExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.lightBg,
      body: const _ExerciseContent(),
      floatingActionButton: _LogExerciseFab(),
    );
  }
}

class _LogExerciseFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.health,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.fitness_center),
      label: const Text('Log Workout'),
      onPressed: () => _showLogExerciseDialog(context, ref),
    );
  }
}

class _ExerciseContent extends ConsumerWidget {
  const _ExerciseContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(exerciseEntriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = Spacing.pagePadding(context);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (allEntries) {
        final todayEntries = allEntries
            .where((e) => DateFormat('yyyy-MM-dd').format(e.date) == todayKey)
            .toList();
        final todayMins = todayEntries.fold(0, (s, e) => s + e.durationMins);
        final todayCals = todayEntries.fold(0, (s, e) => s + e.caloriesBurned);

        final pastEntries = allEntries
            .where((e) => DateFormat('yyyy-MM-dd').format(e.date) != todayKey)
            .toList();
        final byDate = <String, List<ExerciseEntry>>{};
        for (final e in pastEntries) {
          final k = DateFormat('yyyy-MM-dd').format(e.date);
          (byDate[k] ??= []).add(e);
        }
        final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        // Weekly stats (last 7 days)
        final weekStart = DateTime.now().subtract(const Duration(days: 6));
        final weekEntries = allEntries.where((e) => e.date.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();
        final weekMins = weekEntries.fold(0, (s, e) => s + e.durationMins);
        final weekCals = weekEntries.fold(0, (s, e) => s + e.caloriesBurned);

        return ListView(
          padding: pad,
          children: [
            _StatsRow(todayMins: todayMins, todayCals: todayCals, weekMins: weekMins, weekCals: weekCals, isDark: isDark),
            const Gap(16),
            _TypeBreakdown(entries: weekEntries, isDark: isDark),
            const Gap(16),
            _TodayWorkouts(entries: todayEntries, isDark: isDark),
            const Gap(16),
            if (sortedDates.isNotEmpty) _PastDaysSection(byDate: byDate, sortedDates: sortedDates, isDark: isDark),
          ],
        );
      },
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.todayMins, required this.todayCals,
    required this.weekMins, required this.weekCals, required this.isDark,
  });
  final int todayMins, todayCals, weekMins, weekCals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(label: 'Today', value: '$todayMins min', sub: '$todayCals kcal burned', isDark: isDark)),
      const Gap(12),
      Expanded(child: _StatCard(label: 'This Week', value: '$weekMins min', sub: '$weekCals kcal burned', isDark: isDark)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.sub, required this.isDark});
  final String label, value, sub;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textSec)),
          const Gap(6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPri, fontFamily: 'Roboto', height: 1.1)),
          const Gap(2),
          Text(sub, style: TextStyle(fontSize: 11, color: textSec)),
        ],
      ),
    );
  }
}

// ── Weekly type breakdown ─────────────────────────────────────────
class _TypeBreakdown extends StatelessWidget {
  const _TypeBreakdown({required this.entries, required this.isDark});
  final List<ExerciseEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final byType = <ExerciseType, int>{};
    for (final e in entries) {
      byType[e.exerciseType] = (byType[e.exerciseType] ?? 0) + e.durationMins;
    }
    final sorted = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week by Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPri)),
          const Gap(12),
          ...sorted.map((entry) {
            final total = byType.values.fold(0, (s, v) => s + v);
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(entry.key.icon, style: const TextStyle(fontSize: 16)),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(entry.key.label, style: TextStyle(fontSize: 12, color: textSec)),
                        const Spacer(),
                        Text('${entry.value} min', style: TextStyle(fontSize: 12, fontFamily: 'Roboto', color: textPri)),
                      ]),
                      const Gap(3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: isDark ? AppColors.border : AppColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation(entry.key.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ── Today's workouts ──────────────────────────────────────────────
class _TodayWorkouts extends ConsumerWidget {
  const _TodayWorkouts({required this.entries, required this.isDark});
  final List<ExerciseEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Today's Workouts", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPri)),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text('No workouts logged today. Tap "Log Workout" to add one.', style: TextStyle(fontSize: 13, color: textSec)),
            )
          else
            ...entries.map((e) => Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red.withValues(alpha: 0.12),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
              onDismissed: (_) => ref.read(exerciseEntriesProvider.notifier).delete(e.id),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: e.exerciseType.color.withValues(alpha: 0.15),
                  child: Text(e.exerciseType.icon, style: const TextStyle(fontSize: 16)),
                ),
                title: Text(e.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPri)),
                subtitle: Text('${e.exerciseType.label}${e.note != null ? " · ${e.note}" : ""}',
                    style: TextStyle(fontSize: 12, color: textSec)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${e.durationMins} min', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPri, fontFamily: 'Roboto')),
                    if (e.caloriesBurned > 0)
                      Text('${e.caloriesBurned} kcal', style: TextStyle(fontSize: 11, color: textSec)),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

// ── Past days ─────────────────────────────────────────────────────
class _PastDaysSection extends ConsumerWidget {
  const _PastDaysSection({required this.byDate, required this.sortedDates, required this.isDark});
  final Map<String, List<ExerciseEntry>> byDate;
  final List<String> sortedDates;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPri)),
          ),
          ...sortedDates.take(14).map((dateKey) {
            final dayEntries = byDate[dateKey]!;
            final dayMins = dayEntries.fold(0, (s, e) => s + e.durationMins);
            final date = DateTime.tryParse(dateKey) ?? DateTime.now();
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(DateFormat('EEE, MMM d').format(date), style: TextStyle(fontSize: 13, color: textPri)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$dayMins min', style: TextStyle(fontSize: 12, color: AppColors.health, fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
                const Gap(4),
                const Icon(Icons.expand_more, size: 18),
              ]),
              children: dayEntries.map((e) => ListTile(
                dense: true,
                leading: Text(e.exerciseType.icon, style: const TextStyle(fontSize: 16)),
                title: Text(e.name, style: TextStyle(fontSize: 12, color: textPri)),
                subtitle: Text(e.exerciseType.label, style: TextStyle(fontSize: 11, color: textSec)),
                trailing: Text('${e.durationMins} min', style: TextStyle(fontSize: 12, color: textSec, fontFamily: 'Roboto')),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// ── Log exercise dialog ───────────────────────────────────────────
void _showLogExerciseDialog(BuildContext context, WidgetRef ref) {
  ExerciseType selectedType = ExerciseType.cardio;
  final nameCtrl = TextEditingController();
  final durCtrl = TextEditingController();
  final calCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Log Workout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type', style: TextStyle(fontSize: 12)),
              const Gap(8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ExerciseType.values.map((t) => FilterChip(
                  label: Text('${t.icon} ${t.label}', style: const TextStyle(fontSize: 12)),
                  selected: selectedType == t,
                  selectedColor: t.color.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => selectedType = t),
                )).toList(),
              ),
              const Gap(12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Morning run'),
              ),
              const Gap(8),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              ),
              const Gap(8),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories burned (optional)'),
              ),
              const Gap(8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final dur = int.tryParse(durCtrl.text.trim()) ?? 0;
              final cal = int.tryParse(calCtrl.text.trim()) ?? 0;
              if (name.isEmpty || dur <= 0) return;
              ref.read(exerciseEntriesProvider.notifier).add(
                name: name,
                exerciseType: selectedType,
                durationMins: dur,
                caloriesBurned: cal,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: Text('Log', style: TextStyle(color: AppColors.health)),
          ),
        ],
      ),
    ),
  );
}
