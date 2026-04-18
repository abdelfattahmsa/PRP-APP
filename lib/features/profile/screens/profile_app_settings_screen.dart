import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/widgets/placeholders.dart';

class ProfileAppSettingsScreen extends ConsumerStatefulWidget {
  const ProfileAppSettingsScreen({super.key});

  @override
  ConsumerState<ProfileAppSettingsScreen> createState() =>
      _ProfileAppSettingsScreenState();
}

class _ProfileAppSettingsScreenState
    extends ConsumerState<ProfileAppSettingsScreen> {
  bool _notifyFocus = true;
  bool _notifyGoals = true;
  bool _notifyHabits = false;
  bool _notifyFasting = true;
  bool _compactMode = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'App Settings',
              subtitle: 'Theme, notifications, and display',
            ),
            const Gap(24),

            // ── Theme ──────────────────────────────────────────
            const SectionHeader('Appearance'),
            const Gap(12),
            SectionCard(children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        _ThemeOption(
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          selected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.dark),
                        ),
                        const Gap(8),
                        _ThemeOption(
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          selected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.light),
                        ),
                        const Gap(8),
                        _ThemeOption(
                          label: 'System',
                          icon: Icons.brightness_auto_rounded,
                          selected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Compact Mode',
                subtitle: 'Reduce spacing for more content',
                leading: const Icon(Icons.compress_rounded, size: 20),
                value: _compactMode,
                onChanged: (v) => setState(() => _compactMode = v),
              ),
            ]),
            const Gap(24),

            // ── Notifications ──────────────────────────────────
            const SectionHeader('Notifications'),
            const Gap(12),
            SectionCard(children: [
              SettingsSwitchTile(
                title: 'Focus Reminders',
                subtitle: 'Remind to start focus sessions',
                leading: const Icon(Icons.timer_outlined, size: 20),
                value: _notifyFocus,
                onChanged: (v) => setState(() => _notifyFocus = v),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Goal Updates',
                subtitle: 'Notify on goal milestones',
                leading: const Icon(Icons.flag_outlined, size: 20),
                value: _notifyGoals,
                onChanged: (v) => setState(() => _notifyGoals = v),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Habit Reminders',
                subtitle: 'Daily habit check-in prompts',
                leading: const Icon(Icons.check_circle_outline, size: 20),
                value: _notifyHabits,
                onChanged: (v) => setState(() => _notifyHabits = v),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Fasting Alerts',
                subtitle: 'Fast start/end reminders',
                leading: const Icon(Icons.hourglass_empty_rounded, size: 20),
                value: _notifyFasting,
                onChanged: (v) => setState(() => _notifyFasting = v),
              ),
            ]),
            const Gap(24),

            // ── Schedule ────────────────────────────────────────
            const SectionHeader('Schedule & Time'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Schedule Mode',
                subtitle: 'Normal',
                leading: const Icon(Icons.view_timeline_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Day Start Time',
                subtitle: '06:00',
                leading: const Icon(Icons.wb_sunny_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'First Day of Week',
                subtitle: 'Monday',
                leading: const Icon(Icons.date_range_outlined, size: 20),
                onTap: () {},
              ),
            ]),
            const Gap(24),

            // ── About ───────────────────────────────────────────
            const SectionHeader('About'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'App Version',
                subtitle: 'PRP System v3.0.0',
                leading:
                    Icon(Icons.info_outline, color: accent, size: 20),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Terms of Service',
                leading: const Icon(Icons.description_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Privacy Policy',
                leading: const Icon(Icons.privacy_tip_outlined, size: 20),
                onTap: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? AppColors.cardHover : AppColors.lightCardHover;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? accent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ),
              const Gap(4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? accent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
