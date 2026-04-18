import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: Spacing.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Health', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: Spacing.sm),
              Text(
                'Track your vitals, sleep, and fitness.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: Spacing.xxl),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_outline,
                        size: 48, color: accent.withValues(alpha: 0.4)),
                    const SizedBox(height: Spacing.base),
                    Text(
                      'Health tracking coming soon',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
