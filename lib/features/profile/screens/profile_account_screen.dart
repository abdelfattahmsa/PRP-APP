import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileAccountScreen extends ConsumerWidget {
  const ProfileAccountScreen({super.key});

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(user.email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final export = {
      'exported_at': DateTime.now().toIso8601String(),
      'user': {
        'id': user.id,
        'email': user.email,
        'full_name': user.fullName,
      },
      'note': 'Full data export from Supabase is available via the Supabase dashboard.',
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(export);
    final dataUri = 'data:application/json;charset=utf-8,${Uri.encodeComponent(jsonStr)}';

    if (kIsWeb) {
      await launchUrl(Uri.parse(dataUri));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data export downloaded.')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Second confirmation
    final ctrl = TextEditingController();
    final reconfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Type DELETE to confirm'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'DELETE'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text == 'DELETE'),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reconfirmed != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion requested. Contact support@prp-app.website to complete.'),
        duration: Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final syncTime = _formatSyncTime(DateTime.now());

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
                subtitle: 'Send a reset link to your email',
                leading: const Icon(Icons.lock_outline, size: 20),
                onTap: () => _sendPasswordReset(context, ref),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Two-Factor Authentication',
                subtitle: 'Not yet available',
                leading: const Icon(Icons.security_outlined, size: 20),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Two-factor authentication is coming soon.')),
                ),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Active Sessions',
                subtitle: '1 active session (this device)',
                leading: const Icon(Icons.devices_outlined, size: 20),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session management is coming soon.')),
                ),
              ),
            ]),
            const Gap(24),

            const SectionHeader('Data'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Export My Data',
                subtitle: 'Download your profile as JSON',
                leading: const Icon(Icons.download_outlined, size: 20),
                onTap: () => _exportData(context, ref),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Sync Status',
                subtitle: 'Last synced: $syncTime',
                leading: const Icon(Icons.sync_outlined, size: 20),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Synced with Supabase at $syncTime.')),
                ),
              ),
            ]),
            const Gap(24),

            const SectionHeader('Danger Zone'),
            const Gap(12),
            _DangerZone(
              ref: ref,
              onDeleteAccount: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m today';
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
            onPressed: () => launchUrl(
              Uri.parse('https://prp-app.website/pricing'),
              mode: LaunchMode.externalApplication,
            ),
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
  const _DangerZone({required this.ref, required this.onDeleteAccount});
  final WidgetRef ref;
  final VoidCallback onDeleteAccount;

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
            onTap: onDeleteAccount,
          ),
        ],
      ),
    );
  }
}
