import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/providers/health_providers.dart';

// ══════════════════════════════════════════════════════════════════
// HEALTH SYNC BANNER
// Shows sync status and a "Sync now" button on supported platforms.
// Shows "Manual entry only" on Windows / Linux / Web.
// ══════════════════════════════════════════════════════════════════
class HealthSyncBanner extends ConsumerWidget {
  const HealthSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncAsync = ref.watch(healthSyncProvider);
    final notifier = ref.read(healthSyncProvider.notifier);

    // Not a supported platform — show simple info chip
    if (!notifier.isSupported) {
      return _InfoChip(
        icon: Icons.edit_note_outlined,
        label: 'Manual entry only on this platform',
        isDark: isDark,
      );
    }

    return syncAsync.when(
      loading: () => _SyncCard(
        icon: Icons.sync,
        spinning: true,
        label: 'Syncing from ${notifier.platformName}…',
        sub: null,
        action: null,
        isDark: isDark,
      ),
      error: (e, _) => _SyncCard(
        icon: Icons.error_outline,
        spinning: false,
        label: 'Sync failed',
        sub: '$e',
        action: _SyncButton(label: 'Retry', onTap: () => notifier.sync()),
        isDark: isDark,
      ),
      data: (result) {
        if (result == null) {
          return _SyncCard(
            icon: Icons.health_and_safety_outlined,
            spinning: false,
            label: 'Connect to ${notifier.platformName}',
            sub: 'Sync weight, heart rate, steps & sleep automatically',
            action: _SyncButton(label: 'Connect', onTap: () => notifier.sync()),
            isDark: isDark,
          );
        }
        if (!result.permissionGranted) {
          return _SyncCard(
            icon: Icons.lock_outline,
            spinning: false,
            label: 'Permission required',
            sub: 'Tap to grant access to ${notifier.platformName}',
            action: _SyncButton(label: 'Grant access', onTap: () => notifier.sync()),
            isDark: isDark,
          );
        }
        if (!result.available) {
          return _InfoChip(
            icon: Icons.edit_note_outlined,
            label: 'Manual entry only on this platform',
            isDark: isDark,
          );
        }

        final syncedAt = result.syncedAt != null
            ? DateFormat('h:mm a').format(result.syncedAt!)
            : '—';

        return _SyncCard(
          icon: Icons.check_circle_outline,
          spinning: false,
          iconColor: Colors.green,
          label: 'Synced from ${notifier.platformName}',
          sub: 'Last sync: $syncedAt · '
              '${result.steps > 0 ? "${result.steps} steps · " : ""}'
              '${result.activeCaloriesBurned > 0 ? "${result.activeCaloriesBurned} kcal burned · " : ""}'
              '${result.avgHeartRate != null ? "${result.avgHeartRate!.round()} bpm avg" : ""}',
          action: _SyncButton(label: 'Sync again', onTap: () => notifier.sync()),
          isDark: isDark,
        );
      },
    );
  }
}

// ── Today stats strip (shown after a successful sync) ─────────────
class HealthSyncStatsStrip extends ConsumerWidget {
  const HealthSyncStatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(healthSyncProvider).value;
    if (result == null || !result.available || !result.permissionGranted) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <(String, String)>[
      if (result.steps > 0) ('👟', '${result.steps} steps'),
      if (result.activeCaloriesBurned > 0) ('🔥', '${result.activeCaloriesBurned} kcal'),
      if (result.avgHeartRate != null) ('❤️', '${result.avgHeartRate!.round()} bpm'),
      if (result.sleepHours > 0) ('😴', '${result.sleepHours.toStringAsFixed(1)}h sleep'),
      if (result.latestWeightKg != null) ('⚖️', '${result.latestWeightKg!.toStringAsFixed(1)} kg'),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.health.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.health.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(item.$1, style: const TextStyle(fontSize: 13)),
              const Gap(4),
              Text(
                item.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────
class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.icon,
    required this.spinning,
    required this.label,
    required this.sub,
    required this.action,
    required this.isDark,
    this.iconColor,
  });
  final IconData icon;
  final bool spinning;
  final String label;
  final String? sub;
  final Widget? action;
  final bool isDark;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final effectiveColor = iconColor ?? AppColors.health;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        spinning
            ? SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.health,
                ),
              )
            : Icon(icon, size: 18, color: effectiveColor),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPri)),
              if (sub != null && sub!.isNotEmpty) ...[
                const Gap(2),
                Text(sub!, style: TextStyle(fontSize: 11, color: textSec), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
        if (action != null) ...[const Gap(8), action!],
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: isDark ? AppColors.textMuted : AppColors.lightTextMuted),
      const Gap(6),
      Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.lightTextMuted)),
    ]);
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(color: AppColors.health, fontSize: 12)),
    );
  }
}
