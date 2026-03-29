import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/providers/auth_provider.dart';

// ignore: library_private_types_in_public_api
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  static const _destinations = [
    _NavDest(route: Routes.overview, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Overview'),
    _NavDest(route: Routes.schedule, icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Schedule'),
    _NavDest(route: Routes.calendar, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendar'),
    _NavDest(route: Routes.finance, icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance'),
    _NavDest(route: Routes.habits, icon: Icons.check_circle_outline, activeIcon: Icons.check_circle, label: 'Habits'),
    _NavDest(route: Routes.goals, icon: Icons.flag_outlined, activeIcon: Icons.flag, label: 'Goals'),
    _NavDest(route: Routes.focus, icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'Focus'),
  ];

  int get _selectedIndex {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final userAsync = ref.watch(currentUserProvider);

    if (isWide) {
      // ── DESKTOP: Navigation Rail ─────────────────────────────
      return Scaffold(
        body: Row(
          children: [
            // Rail
            Container(
              width: 200,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  // App brand
                  const _Brand(),
                  const Divider(),
                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _destinations.length,
                      itemBuilder: (ctx, i) {
                        final dest = _destinations[i];
                        final active = i == _selectedIndex;
                        return _RailItem(
                          dest: dest,
                          active: active,
                          onTap: () => context.go(dest.route),
                        );
                      },
                    ),
                  ),
                  // User section
                  _UserFooter(userAsync: userAsync, ref: ref),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Scaffold(
                body: child,
              ),
            ),
          ],
        ),
      );
    } else {
      // ── MOBILE: Bottom Navigation Bar ────────────────────────
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => context.go(_destinations[i].route),
          destinations: _destinations.map((d) => NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.activeIcon),
            label: d.label,
          )).toList(),
        ),
      );
    }
  }
}

class _NavDest {
  const _NavDest({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.goldDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 14, color: AppColors.gold),
              ),
              const Gap(10),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'PlayfairDisplay',
                    ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            '2026',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.goldDim,
                  letterSpacing: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.dest, required this.active, required this.onTap});
  final _NavDest dest;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: active ? AppColors.gold.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  active ? dest.activeIcon : dest.icon,
                  color: color,
                  size: 20,
                ),
                const Gap(12),
                Text(
                  dest.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.userAsync, required this.ref});
  final AsyncValue userAsync;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: userAsync.when(
        data: (user) => Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.goldDim,
              child: Text(
                user?.fullName?.isNotEmpty == true
                    ? user!.fullName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.fullName ?? 'User',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 16),
              color: AppColors.textSecondary,
              tooltip: 'Sign out',
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
