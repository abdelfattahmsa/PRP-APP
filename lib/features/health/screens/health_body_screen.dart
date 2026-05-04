import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/data/models/health_models.dart';
import '../../../engines/health/providers/health_providers.dart';
import '../../../shared/widgets/app_chart.dart';
import '../widgets/health_sync_banner.dart';

class HealthBodyScreen extends ConsumerWidget {
  const HealthBodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: const _BodyContent(),
      floatingActionButton: _LogWeightFab(),
    );
  }
}

class _LogWeightFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.health,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.monitor_weight_outlined),
      label: const Text('Log Weight'),
      onPressed: () => _showLogWeightDialog(context, ref),
    );
  }
}

class _BodyContent extends ConsumerWidget {
  const _BodyContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(bodyProfileProvider);
    final entriesAsync = ref.watch(weightEntriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = Spacing.pagePadding(context);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (profile) => entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          final latest = entries.isNotEmpty ? entries.first : null;
          final bmi = latest != null ? profile.calcBmi(latest.weightKg) : null;

          return ListView(
            padding: pad,
            children: [
              const HealthSyncBanner(),
              const Gap(8),
              const HealthSyncStatsStrip(),
              const Gap(12),
              _TopCards(profile: profile, latest: latest, bmi: bmi, isDark: isDark),
              const Gap(16),
              if (profile.heightCm == null) _SetupBanner(profile: profile, isDark: isDark),
              if (entries.length >= 2) ...[
                _WeightChart(entries: entries, isDark: isDark),
                const Gap(16),
              ],
              _ProfileCard(profile: profile, isDark: isDark),
              const Gap(16),
              _WeightHistory(entries: entries, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

// ── Top cards: Current Weight + BMI ──────────────────────────────
class _TopCards extends StatelessWidget {
  const _TopCards({required this.profile, required this.latest, required this.bmi, required this.isDark});
  final BodyProfile profile;
  final WeightEntry? latest;
  final double? bmi;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Current Weight',
            value: latest != null ? '${latest!.weightKg.toStringAsFixed(1)} kg' : '--',
            sub: latest != null ? DateFormat('MMM d').format(latest!.date) : 'No entries yet',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.health,
            isDark: isDark,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            label: 'BMI',
            value: bmi != null ? bmi!.toStringAsFixed(1) : '--',
            sub: bmi != null ? BodyProfile.bmiCategory(bmi!) : profile.heightCm == null ? 'Set height' : 'No weight',
            icon: Icons.accessibility_new_outlined,
            color: bmi != null ? BodyProfile.bmiColor(bmi!) : AppColors.health,
            isDark: isDark,
          ),
        ),
        if (profile.targetWeightKg != null) ...[
          const Gap(12),
          Expanded(
            child: _StatCard(
              label: 'Goal',
              value: '${profile.targetWeightKg!.toStringAsFixed(1)} kg',
              sub: latest != null
                  ? '${(latest!.weightKg - profile.targetWeightKg!).abs().toStringAsFixed(1)} kg to go'
                  : 'Target weight',
              icon: Icons.flag_outlined,
              color: AppColors.project,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value, required this.sub,
    required this.icon, required this.color, required this.isDark,
  });
  final String label, value, sub;
  final IconData icon;
  final Color color;
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
          Row(children: [
            Icon(icon, size: 16, color: color),
            const Gap(6),
            Text(label, style: TextStyle(fontSize: 11, color: textSec)),
          ]),
          const Gap(8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPri, fontFamily: 'Roboto')),
          const Gap(2),
          Text(sub, style: TextStyle(fontSize: 11, color: textSec)),
        ],
      ),
    );
  }
}

// ── Setup banner ──────────────────────────────────────────────────
class _SetupBanner extends ConsumerWidget {
  const _SetupBanner({required this.profile, required this.isDark});
  final BodyProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.health.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.health.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: AppColors.health, size: 18),
        const Gap(10),
        Expanded(
          child: Text(
            'Set your height to enable BMI calculation.',
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
          ),
        ),
        TextButton(
          onPressed: () => _showProfileDialog(context, ref, profile),
          child: Text('Set up', style: TextStyle(color: AppColors.health, fontSize: 13)),
        ),
      ]),
    );
  }
}

// ── Weight line chart ─────────────────────────────────────────────
class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries, required this.isDark});
  final List<WeightEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final recent = entries.take(14).toList().reversed.toList();
    final weights = recent.map((e) => e.weightKg).toList();
    final labels = recent.map((e) => DateFormat('d/M').format(e.date)).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxW - minW) < 1 ? 2.0 : (maxW - minW) * 0.2;

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
          Text('Weight Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
          const Gap(4),
          Text('Last ${recent.length} entries', style: TextStyle(fontSize: 11, color: textSec)),
          const Gap(12),
          SizedBox(
            height: 120,
            child: AppLineChart(
              data: weights,
              labels: labels,
              color: AppColors.health,
              minY: (minW - padding).clamp(0, double.infinity),
              maxY: maxW + padding,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile settings card ─────────────────────────────────────────
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile, required this.isDark});
  final BodyProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Row(children: [
            Text('Body Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPri)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showProfileDialog(context, ref, profile),
              icon: Icon(Icons.edit_outlined, size: 14, color: AppColors.health),
              label: Text('Edit', style: TextStyle(color: AppColors.health, fontSize: 13)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ]),
          const Gap(12),
          _Row(label: 'Height', value: profile.heightCm != null ? '${profile.heightCm!.toStringAsFixed(0)} cm' : 'Not set', isDark: isDark),
          _Row(label: 'Target weight', value: profile.targetWeightKg != null ? '${profile.targetWeightKg!.toStringAsFixed(1)} kg' : 'Not set', isDark: isDark),
          _Row(label: 'Calorie goal', value: '${profile.calorieGoal} kcal / day', isDark: isDark),
          _Row(label: 'Sex', value: profile.sex != null ? _capitalize(profile.sex!) : 'Not set', isDark: isDark),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.isDark});
  final String label, value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
      ]),
    );
  }
}

// ── Weight history ────────────────────────────────────────────────
class _WeightHistory extends ConsumerWidget {
  const _WeightHistory({required this.entries, required this.isDark});
  final List<WeightEntry> entries;
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
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text('No weight entries yet. Tap "Log Weight" to start.', style: TextStyle(fontSize: 13, color: textSec)),
            )
          else
            ...entries.take(30).map((e) {
              final prev = entries.indexOf(e) < entries.length - 1
                  ? entries[entries.indexOf(e) + 1]
                  : null;
              final diff = prev != null ? e.weightKg - prev.weightKg : 0.0;
              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.withValues(alpha: 0.15),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                confirmDismiss: (_) async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete entry?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  return ok ?? false;
                },
                onDismissed: (_) => ref.read(weightEntriesProvider.notifier).delete(e.id),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.health.withValues(alpha: 0.15),
                    child: Text('${e.weightKg.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: AppColors.health, fontWeight: FontWeight.w700)),
                  ),
                  title: Text('${e.weightKg.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPri)),
                  subtitle: e.note != null ? Text(e.note!, style: TextStyle(fontSize: 12, color: textSec)) : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('MMM d').format(e.date), style: TextStyle(fontSize: 12, color: textSec)),
                      if (prev != null)
                        Text(
                          '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                          style: TextStyle(fontSize: 11, color: diff > 0 ? Colors.red : Colors.green),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────
void _showLogWeightDialog(BuildContext context, WidgetRef ref) {
  final ctrl = TextEditingController();
  final noteCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log Weight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: 'e.g. 75.5'),
            onSubmitted: (_) {},
          ),
          const Gap(8),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final kg = double.tryParse(ctrl.text.trim());
            if (kg == null || kg <= 0 || kg > 500) return;
            ref.read(weightEntriesProvider.notifier).add(
              weightKg: kg,
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            );
            Navigator.pop(ctx);
          },
          child: Text('Save', style: TextStyle(color: AppColors.health)),
        ),
      ],
    ),
  );
}

void _showProfileDialog(BuildContext context, WidgetRef ref, BodyProfile current) {
  final heightCtrl = TextEditingController(text: current.heightCm?.toStringAsFixed(0) ?? '');
  final targetCtrl = TextEditingController(text: current.targetWeightKg?.toStringAsFixed(1) ?? '');
  final calCtrl = TextEditingController(text: '${current.calorieGoal}');
  String? sex = current.sex;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Body Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Height (cm)'),
              ),
              const Gap(8),
              TextField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Target weight (kg)'),
              ),
              const Gap(8),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily calorie goal (kcal)'),
              ),
              const Gap(12),
              Row(children: [
                const Text('Sex:'),
                const Gap(12),
                ...['male', 'female', 'other'].map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_capitalize(s)),
                    selected: sex == s,
                    onSelected: (_) => setState(() => sex = s),
                  ),
                )),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final h = double.tryParse(heightCtrl.text.trim());
              final t = double.tryParse(targetCtrl.text.trim());
              final cal = int.tryParse(calCtrl.text.trim()) ?? current.calorieGoal;
              ref.read(bodyProfileProvider.notifier).save(current.copyWith(
                heightCm: h,
                targetWeightKg: t,
                calorieGoal: cal,
                sex: sex,
              ));
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: AppColors.health)),
          ),
        ],
      ),
    ),
  );
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
