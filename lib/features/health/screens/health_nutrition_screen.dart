import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/data/models/health_models.dart';
import '../../../engines/health/providers/health_providers.dart';

class HealthNutritionScreen extends ConsumerWidget {
  const HealthNutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.lightBg,
      body: const _NutritionContent(),
      floatingActionButton: _LogMealFab(),
    );
  }
}

class _LogMealFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.health,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Log Meal'),
      onPressed: () => _showLogMealDialog(context, ref),
    );
  }
}

class _NutritionContent extends ConsumerWidget {
  const _NutritionContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(bodyProfileProvider);
    final entriesAsync = ref.watch(calorieEntriesProvider);
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
        final todayTotal = todayEntries.fold(0, (s, e) => s + e.calories);
        final calorieGoal = profileAsync.value?.calorieGoal ?? 2000;

        // Group past entries by date (excluding today)
        final pastEntries = allEntries
            .where((e) => DateFormat('yyyy-MM-dd').format(e.date) != todayKey)
            .toList();
        final byDate = <String, List<CalorieEntry>>{};
        for (final e in pastEntries) {
          final k = DateFormat('yyyy-MM-dd').format(e.date);
          (byDate[k] ??= []).add(e);
        }
        final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: pad,
          children: [
            _TodayCard(todayTotal: todayTotal, goal: calorieGoal, isDark: isDark),
            const Gap(16),
            _TodayMealBreakdown(entries: todayEntries, isDark: isDark),
            const Gap(16),
            if (sortedDates.isNotEmpty) ...[
              _PastDaysSection(byDate: byDate, sortedDates: sortedDates, isDark: isDark),
            ],
          ],
        );
      },
    );
  }
}

// ── Today summary card ────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.todayTotal, required this.goal, required this.isDark});
  final int todayTotal;
  final int goal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final pct = goal > 0 ? (todayTotal / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = goal - todayTotal;
    final overGoal = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Calories", style: TextStyle(fontSize: 13, color: textSec)),
          const Gap(12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '$todayTotal',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: textPri, fontFamily: 'Roboto', height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(' / $goal kcal', style: TextStyle(fontSize: 15, color: textSec)),
            ),
          ]),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.border : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(overGoal ? Colors.red : AppColors.health),
            ),
          ),
          const Gap(8),
          Text(
            overGoal
                ? '${(-remaining)} kcal over goal'
                : '$remaining kcal remaining',
            style: TextStyle(fontSize: 12, color: overGoal ? Colors.red : textSec),
          ),
        ],
      ),
    );
  }
}

// ── Today meal breakdown ──────────────────────────────────────────
class _TodayMealBreakdown extends ConsumerWidget {
  const _TodayMealBreakdown({required this.entries, required this.isDark});
  final List<CalorieEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    // Group by meal type
    final byMeal = <MealType, List<CalorieEntry>>{};
    for (final e in entries) {
      (byMeal[e.mealType] ??= []).add(e);
    }

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
            child: Text("Today's Meals", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPri)),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text('Nothing logged yet. Tap "Log Meal" to start.', style: TextStyle(fontSize: 13, color: textSec)),
            )
          else
            ...MealType.values.where((m) => byMeal.containsKey(m)).map((mealType) {
              final mealEntries = byMeal[mealType]!;
              final mealTotal = mealEntries.fold(0, (s, e) => s + e.calories);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(children: [
                      Text(mealType.icon, style: const TextStyle(fontSize: 14)),
                      const Gap(6),
                      Text(mealType.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSec)),
                      const Spacer(),
                      Text('$mealTotal kcal', style: TextStyle(fontSize: 12, color: textSec, fontFamily: 'Roboto')),
                    ]),
                  ),
                  ...mealEntries.map((e) => Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red.withValues(alpha: 0.12),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                    onDismissed: (_) => ref.read(calorieEntriesProvider.notifier).delete(e.id),
                    child: ListTile(
                      dense: true,
                      title: Text(e.description, style: TextStyle(fontSize: 13, color: textPri)),
                      trailing: Text('${e.calories} kcal', style: TextStyle(fontSize: 12, color: AppColors.health, fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
                    ),
                  )),
                  Divider(color: border, height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ── Past days ─────────────────────────────────────────────────────
class _PastDaysSection extends ConsumerWidget {
  const _PastDaysSection({required this.byDate, required this.sortedDates, required this.isDark});
  final Map<String, List<CalorieEntry>> byDate;
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
          ...sortedDates.take(7).map((dateKey) {
            final dayEntries = byDate[dateKey]!;
            final dayTotal = dayEntries.fold(0, (s, e) => s + e.calories);
            final date = DateTime.tryParse(dateKey) ?? DateTime.now();
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(DateFormat('EEE, MMM d').format(date), style: TextStyle(fontSize: 13, color: textPri)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$dayTotal kcal', style: TextStyle(fontSize: 12, color: AppColors.health, fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
                const Gap(4),
                const Icon(Icons.expand_more, size: 18),
              ]),
              children: dayEntries.map((e) => ListTile(
                dense: true,
                leading: Text(e.mealType.icon),
                title: Text(e.description, style: TextStyle(fontSize: 12, color: textPri)),
                trailing: Text('${e.calories}', style: TextStyle(fontSize: 12, color: textSec, fontFamily: 'Roboto')),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// ── Log meal dialog ───────────────────────────────────────────────
void _showLogMealDialog(BuildContext context, WidgetRef ref) {
  MealType selectedMeal = MealType.breakfast;
  final descCtrl = TextEditingController();
  final calCtrl = TextEditingController();

  // Smart default based on time of day
  final h = DateTime.now().hour;
  if (h < 10) selectedMeal = MealType.breakfast;
  else if (h < 14) selectedMeal = MealType.lunch;
  else if (h < 17) selectedMeal = MealType.snack;
  else if (h < 21) selectedMeal = MealType.dinner;
  else selectedMeal = MealType.snack;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Log Meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meal type', style: TextStyle(fontSize: 12)),
              const Gap(8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: MealType.values.map((m) => FilterChip(
                  label: Text('${m.icon} ${m.label}', style: const TextStyle(fontSize: 12)),
                  selected: selectedMeal == m,
                  onSelected: (_) => setState(() => selectedMeal = m),
                )).toList(),
              ),
              const Gap(12),
              TextField(
                controller: descCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Oatmeal with berries'),
              ),
              const Gap(8),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories (kcal)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final cal = int.tryParse(calCtrl.text.trim());
              final desc = descCtrl.text.trim();
              if (cal == null || cal <= 0 || desc.isEmpty) return;
              ref.read(calorieEntriesProvider.notifier).add(
                mealType: selectedMeal,
                description: desc,
                calories: cal,
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
