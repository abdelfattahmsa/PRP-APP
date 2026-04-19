import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Profile',
              subtitle: 'Your personal information',
            ),
            const Gap(24),

            // Avatar + name card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Text(
                      user?.fullName?.isNotEmpty == true
                          ? user!.fullName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const Gap(Spacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Gap(4),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: textSecondary),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Free Plan',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    color: textSecondary,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const Gap(24),

            const SectionHeader('Personal Info'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Full Name',
                subtitle: 'Update your display name',
                leading: const Icon(Icons.person_outline, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Email Address',
                subtitle: 'Change your login email',
                leading: const Icon(Icons.email_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Phone Number',
                subtitle: 'Not set',
                leading: const Icon(Icons.phone_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Timezone',
                subtitle: 'UTC+3 (Cairo)',
                leading: const Icon(Icons.language_outlined, size: 20),
                onTap: () {},
              ),
            ]),
            const Gap(24),

            const SectionHeader('Preferences'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Language',
                subtitle: 'English',
                leading: const Icon(Icons.translate_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Currency',
                subtitle: 'USD (\$)',
                leading: const Icon(Icons.attach_money_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Date Format',
                subtitle: 'DD/MM/YYYY',
                leading: const Icon(Icons.calendar_today_outlined, size: 20),
                onTap: () {},
              ),
            ]),
            const Gap(24),

            const SectionHeader('Help & Support'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Documentation',
                subtitle: 'Guides and how-to articles',
                leading: const Icon(Icons.menu_book_outlined, size: 20),
                onTap: () => launchUrl(
                  Uri.parse('https://prp-app.website/docs'),
                  mode: LaunchMode.externalApplication,
                ),
                trailing: const Icon(Icons.open_in_new, size: 16),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Download for Windows',
                subtitle: 'Coming soon',
                leading: const Icon(Icons.computer_outlined, size: 20),
                onTap: () {},
                trailing: _ComingSoonBadge(),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Android & iOS',
                subtitle: 'Mobile apps — coming soon',
                leading: const Icon(Icons.phone_android_outlined, size: 20),
                onTap: () {},
                trailing: _ComingSoonBadge(),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'App Version',
                subtitle: 'PRP v4.2.0',
                leading: const Icon(Icons.info_outline, size: 20),
                onTap: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Soon',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}
