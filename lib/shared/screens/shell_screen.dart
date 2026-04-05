import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

// ══════════════════════════════════════════════════════════════
// SHELL SCREEN — Responsive navigation container
// Mobile: Bottom nav (5 primary + More sheet)
// Desktop: Collapsible side rail
// ══════════════════════════════════════════════════════════════

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  // Primary destinations (shown on bottom nav)
  static const _primary = [
    _NavDest(route: Routes.overview, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Overview'),
    _NavDest(route: Routes.schedule, icon: Icons.view_timeline_outlined, activeIcon: Icons.view_timeline, label: 'Schedule'),
    _NavDest(route: Routes.calendar, icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Calendar'),
    _NavDest(route: Routes.finance, icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance'),
  ];

  // Secondary destinations (shown in More sheet on mobile)
  static const _secondary = [
    _NavDest(route: Routes.habits, icon: Icons.check_circle_outline, activeIcon: Icons.check_circle, label: 'Habits'),
    _NavDest(route: Routes.goals, icon: Icons.flag_outlined, activeIcon: Icons.flag, label: 'Goals'),
    _NavDest(route: Routes.focus, icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'Focus'),
    _NavDest(route: Routes.settings, icon: Icons.tune_outlined, activeIcon: Icons.tune, label: 'Settings'),
  ];

  static List<_NavDest> get _all => [..._primary, ..._secondary];

  int _indexOf(List<_NavDest> dests) {
    for (var i = 0; i < dests.length; i++) {
      if (location.startsWith(dests[i].route)) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Breakpoints.isWide(context)) {
      return _DesktopShell(
        location: location,
        destinations: _all,
        selectedIndex: _indexOf(_all),
        child: child,
      );
    }
    return _MobileShell(
      location: location,
      primary: _primary,
      secondary: _secondary,
      selectedPrimary: _indexOf(_primary),
      isSecondaryActive: _indexOf(_secondary) >= 0,
      child: child,
    );
  }
}

// ── DESKTOP LAYOUT ───────────────────────────────────────────

class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell({
    required this.location,
    required this.destinations,
    required this.selectedIndex,
    required this.child,
  });
  final String location;
  final List<_NavDest> destinations;
  final int selectedIndex;
  final Widget child;

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  late bool _expanded = Breakpoints.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final railWidth = _expanded ? 200.0 : 64.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ── Navigation rail ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: railWidth,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Column(
              children: [
                // Brand
                _RailBrand(expanded: _expanded, onToggle: () => setState(() => _expanded = !_expanded)),
                const Divider(height: 1),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    children: [
                      for (var i = 0; i < widget.destinations.length; i++) ...[
                        if (i == 4) // divider between primary & secondary
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _expanded ? 16.0 : 12.0,
                              vertical: Spacing.xs,
                            ),
                            child: const Divider(height: 1),
                          ),
                        _RailItem(
                          dest: widget.destinations[i],
                          active: i == widget.selectedIndex,
                          expanded: _expanded,
                          onTap: () => context.go(widget.destinations[i].route),
                        ),
                      ],
                    ],
                  ),
                ),
                // User footer
                const Divider(height: 1),
                _UserFooter(userAsync: userAsync, ref: ref, expanded: _expanded),
              ],
            ),
          ),
          // ── Main content ──
          Expanded(
            child: ClipRect(child: widget.child),
          ),
        ],
      ),
    );
  }
}

// ── MOBILE LAYOUT ────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.location,
    required this.primary,
    required this.secondary,
    required this.selectedPrimary,
    required this.isSecondaryActive,
    required this.child,
  });
  final String location;
  final List<_NavDest> primary;
  final List<_NavDest> secondary;
  final int selectedPrimary;
  final bool isSecondaryActive;
  final Widget child;

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(Spacing.sm),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(Spacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.base),
              child: Text('More', style: Theme.of(ctx).textTheme.headlineMedium),
            ),
            const Gap(Spacing.md),
            for (final dest in secondary)
              _MoreSheetItem(
                dest: dest,
                active: location.startsWith(dest.route),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(dest.route);
                },
              ),
            const Gap(Spacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute bottom nav index: 0-3 for primary, 4 for More
    final navIndex = selectedPrimary >= 0 ? selectedPrimary : 4;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: navIndex.clamp(0, 4),
          onDestinationSelected: (i) {
            if (i < primary.length) {
              context.go(primary[i].route);
            } else {
              _showMoreSheet(context);
            }
          },
          destinations: [
            for (final d in primary)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: d.label,
              ),
            NavigationDestination(
              icon: Icon(
                isSecondaryActive ? Icons.more_horiz : Icons.more_horiz_outlined,
                color: isSecondaryActive ? AppColors.gold : null,
              ),
              selectedIcon: const Icon(Icons.more_horiz, color: AppColors.gold),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

// ── SHARED COMPONENTS ────────────────────────────────────────

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

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.expanded, required this.onToggle});
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          expanded ? 16 : 12,
          20,
          expanded ? 12 : 12,
          16,
        ),
        child: Row(
          children: [
            // Diamond mark
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'PRP',
                  style: TextStyle(
                    color: AppColors.bg,
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            if (expanded) ...[
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 14,
                          ),
                    ),
                    Text(
                      'v${AppConstants.appVersion}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.goldDim,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                expanded ? Icons.chevron_left : Icons.chevron_right,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.dest,
    required this.active,
    required this.expanded,
    required this.onTap,
  });
  final _NavDest dest;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textSecondary;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 8.0 : 6.0,
        vertical: 1,
      ),
      child: Material(
        color: active ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.gold.withValues(alpha: 0.05),
          child: Tooltip(
            message: expanded ? '' : dest.label,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 12.0 : 0,
                vertical: expanded ? 10.0 : 12.0,
              ),
              child: expanded
                  ? Row(
                      children: [
                        Icon(active ? dest.activeIcon : dest.icon, color: color, size: 18),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            dest.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: color,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        if (active)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(active ? dest.activeIcon : dest.icon, color: color, size: 20),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreSheetItem extends StatelessWidget {
  const _MoreSheetItem({
    required this.dest,
    required this.active,
    required this.onTap,
  });
  final _NavDest dest;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textPrimary;
    return ListTile(
      leading: Icon(active ? dest.activeIcon : dest.icon, color: color, size: 22),
      title: Text(
        dest.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
      trailing: active
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: active ? AppColors.gold.withValues(alpha: 0.08) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.userAsync, required this.ref, required this.expanded});
  final AsyncValue userAsync;
  final WidgetRef ref;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.sm),
      child: userAsync.when(
        data: (user) {
          final initial = user?.fullName?.isNotEmpty == true
              ? user!.fullName![0].toUpperCase()
              : '?';
          if (!expanded) {
            return Center(
              child: Tooltip(
                message: user?.fullName ?? 'User',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.goldDim,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }
          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.goldDim,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 14),
                color: AppColors.textMuted,
                tooltip: 'Sign out',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
