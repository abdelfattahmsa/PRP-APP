import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileAccountScreen extends ConsumerWidget {
  const ProfileAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Account',
              subtitle: 'Security and subscription',
            ),
            const Gap(24),

            const SectionHeader('Subscription'),
            const Gap(12),
            _PlanCard(),
            const Gap(24),

            const SectionHeader('Security'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Change Password',
                subtitle: 'Last changed 30 days ago',
                leading: const Icon(Icons.lock_outline, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Two-Factor Authentication',
                subtitle: 'Not enabled',
                leading: const Icon(Icons.security_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Active Sessions',
                subtitle: '1 device',
                leading: const Icon(Icons.devices_outlined, size: 20),
                onTap: () {},
              ),
            ]),
            const Gap(24),

            const SectionHeader('Data'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Export My Data',
                subtitle: 'Download all your data as JSON',
                leading: const Icon(Icons.download_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Sync Status',
                subtitle: 'Last synced: Just now',
                leading: const Icon(Icons.sync_outlined, size: 20),
                onTap: () {},
              ),
            ]),
            const Gap(24),

            const SectionHeader('Danger Zone'),
            const Gap(12),
            _DangerZone(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(Spacing.base),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.workspace_premium_rounded, color: accent, size: 22),
          ),
          const Gap(Spacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Plan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Basic features included',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 11, fontFamily: 'IBMPlexMono'),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: Spacing.base, vertical: 2),
            leading: const Icon(Icons.logout_rounded,
                color: AppColors.warning, size: 20),
            title: Text(
              'Sign Out',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Sign out of your account',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: Spacing.base, vertical: 2),
            leading: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error, size: 20),
            title: Text(
              'Delete Account',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                      fontWeight: FontWeight.w500, color: AppColors.error),
            ),
            subtitle: Text(
              'Permanently delete all data',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
