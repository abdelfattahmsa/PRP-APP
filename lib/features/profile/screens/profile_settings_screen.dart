import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
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
              child: userAsync.when(
                data: (user) => Row(
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
                loading: () => const SizedBox(
                    height: 64,
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
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
          ],
        ),
      ),
    );
  }
}
