import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

// ══════════════════════════════════════════════════════════════
// NAVIGATION MODEL
// ══════════════════════════════════════════════════════════════

class AppSubTab {
  const AppSubTab({
    required this.label,
    required this.icon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final String route;
}

class AppTab {
  const AppTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.subTabs = const [],
  });
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  /// The route navigated to when this tab is tapped.
  /// For tabs with sub-tabs this points to the first sub-tab.
  final String route;
  final List<AppSubTab> subTabs;
  bool get hasSubTabs => subTabs.isNotEmpty;
}

// ── 6 MAIN TABS ──────────────────────────────────────────────
const kAppTabs = <AppTab>[
  AppTab(
    id: 'overview',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: Routes.overview,
  ),
  AppTab(
    id: 'time',
    label: 'Time',
    icon: Icons.schedule_outlined,
    activeIcon: Icons.schedule_rounded,
    route: Routes.timeOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.timeOverview),
      AppSubTab(
          label: 'Calendar',
          icon: Icons.event_outlined,
          route: Routes.timeCalendar),
      AppSubTab(
          label: 'Schedule',
          icon: Icons.view_timeline_outlined,
          route: Routes.timeSchedule),
    ],
  ),
  AppTab(
    id: 'finance',
    label: 'Finance',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    route: Routes.financeOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.financeOverview),
      AppSubTab(
          label: 'Accounts',
          icon: Icons.account_balance_outlined,
          route: Routes.financeAccounts),
      AppSubTab(
          label: 'Invest',
          icon: Icons.trending_up_outlined,
          route: Routes.financeInvestments),
      AppSubTab(
          label: 'Debts',
          icon: Icons.trending_down_outlined,
          route: Routes.financeLiabilities),
      AppSubTab(
          label: 'Txns',
          icon: Icons.receipt_long_outlined,
          route: Routes.financeTransactions),
    ],
  ),
  AppTab(
    id: 'energy',
    label: 'Energy',
    icon: Icons.bolt_outlined,
    activeIcon: Icons.bolt_rounded,
    route: Routes.energyOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.energyOverview),
      AppSubTab(
          label: 'Focus',
          icon: Icons.timer_outlined,
          route: Routes.energyFocus),
      AppSubTab(
          label: 'Goals',
          icon: Icons.flag_outlined,
          route: Routes.energyGoals),
    ],
  ),
  AppTab(
    id: 'health',
    label: 'Health',
    icon: Icons.favorite_outline,
    activeIcon: Icons.favorite_rounded,
    route: Routes.healthOverview,
    subTabs: [
      AppSubTab(
          label: 'Overview',
          icon: Icons.bar_chart_outlined,
          route: Routes.healthOverview),
      AppSubTab(
          label: 'Progress',
          icon: Icons.trending_up_outlined,
          route: Routes.healthDailyProgress),
      AppSubTab(
          label: 'Fasting',
          icon: Icons.hourglass_empty,
          route: Routes.healthFasting),
      AppSubTab(
          label: 'Habits',
          icon: Icons.check_circle_outline,
          route: Routes.healthHabits),
    ],
  ),
  AppTab(
    id: 'profile',
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person_rounded,
    route: Routes.profileSettings,
    subTabs: [
      AppSubTab(
          label: 'Profile',
          icon: Icons.person_outline,
          route: Routes.profileSettings),
      AppSubTab(
          label: 'Account',
          icon: Icons.manage_accounts_outlined,
          route: Routes.profileAccount),
      AppSubTab(
          label: 'App',
          icon: Icons.tune_outlined,
          route: Routes.profileApp),
    ],
  ),
];

// ══════════════════════════════════════════════════════════════
// SHELL SCREEN
// ══════════════════════════════════════════════════════════════

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _activeTabIndex {
    for (var i = 0; i < kAppTabs.length; i++) {
      final tab = kAppTabs[i];
      for (final sub in tab.subTabs) {
        if (location.startsWith(sub.route)) return i;
      }
      if (!tab.hasSubTabs && location.startsWith(tab.route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = _activeTabIndex;
    final activeTab = kAppTabs[tabIndex];

    if (Breakpoints.isWide(context)) {
      return _DesktopShell(
        location: location,
        tabIndex: tabIndex,
        child: child,
      );
    }
    return _MobileShell(
      location: location,
      activeTab: activeTab,
      tabIndex: tabIndex,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DESKTOP SHELL
// ══════════════════════════════════════════════════════════════

class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell({
    required this.location,
    required this.tabIndex,
    required this.child,
  });
  final String location;
  final int tabIndex;
  final Widget child;

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expanded = Breakpoints.isDesktop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final railWidth = _expanded ? 200.0 : 64.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // ── Sidebar ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: railWidth,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                  right: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Column(
              children: [
                _SidebarBrand(
                  expanded: _expanded,
                  onToggle: () =>
                      setState(() => _expanded = !_expanded),
                ),
                Divider(height: 1, color: borderColor),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(vertical: Spacing.sm),
                    children: [
                      // Show all tabs except Profile (last) — Profile lives at the bottom
                      for (var i = 0; i < kAppTabs.length - 1; i++) ...[
                        _SidebarTabItem(
                          tab: kAppTabs[i],
                          active: i == widget.tabIndex,
                          expanded: _expanded,
                          onTap: () => context.go(kAppTabs[i].route),
                        ),
                        // Sub-tabs shown when this tab is active
                        if (i == widget.tabIndex &&
                            kAppTabs[i].hasSubTabs &&
                            _expanded)
                          for (final sub in kAppTabs[i].subTabs)
                            _SidebarSubTabItem(
                              sub: sub,
                              active: widget.location.startsWith(sub.route),
                              onTap: () => context.go(sub.route),
                            ),
                        // Collapsed: show active sub-tab indicator dot
                        if (i == widget.tabIndex &&
                            kAppTabs[i].hasSubTabs &&
                            !_expanded)
                          for (final sub in kAppTabs[i].subTabs)
                            _SidebarSubTabItemCollapsed(
                              sub: sub,
                              active: widget.location.startsWith(sub.route),
                              onTap: () => context.go(sub.route),
                            ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                _SidebarProfileFooter(
                  ref: ref,
                  expanded: _expanded,
                  active: widget.tabIndex == kAppTabs.length - 1,
                  location: widget.location,
                ),
              ],
            ),
          ),
          // ── Content ──
          Expanded(child: ClipRect(child: widget.child)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MOBILE SHELL
// ══════════════════════════════════════════════════════════════

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.location,
    required this.activeTab,
    required this.tabIndex,
    required this.child,
  });
  final String location;
  final AppTab activeTab;
  final int tabIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Sub-tab bar sits at top of body when tab has sub-tabs
          if (activeTab.hasSubTabs)
            _MobileSubTabBar(
              subTabs: activeTab.subTabs,
              location: location,
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: (i) => context.go(kAppTabs[i].route),
          destinations: [
            for (final tab in kAppTabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MOBILE SUB-TAB BAR
// ══════════════════════════════════════════════════════════════

class _MobileSubTabBar extends StatelessWidget {
  const _MobileSubTabBar({
    required this.subTabs,
    required this.location,
  });
  final List<AppSubTab> subTabs;
  final String location;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      // Horizontally scrollable so Finance (5 sub-tabs) fits on small screens
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final sub in subTabs)
              _MobileSubTabItem(
                sub: sub,
                active: location.startsWith(sub.route),
                textSecondary: textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileSubTabItem extends StatelessWidget {
  const _MobileSubTabItem({
    required this.sub,
    required this.active,
    required this.textSecondary,
  });
  final AppSubTab sub;
  final bool active;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => context.go(sub.route),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // Minimum width per tab; enough for icon + short label
        width: 80,
        height: 40,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sub.icon,
                    size: 14,
                    color: active ? accent : textSecondary,
                  ),
                  const Gap(4),
                  Text(
                    sub.label,
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? accent : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SIDEBAR COMPONENTS
// ══════════════════════════════════════════════════════════════

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.expanded, required this.onToggle});
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

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
            // Logo mark
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'PRP',
                  style: TextStyle(
                    color: Colors.white,
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
                            color: textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                size: 16,
                color: textMuted,
              ),
            ] else ...[
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarTabItem extends StatelessWidget {
  const _SidebarTabItem({
    required this.tab,
    required this.active,
    required this.expanded,
    required this.onTap,
  });
  final AppTab tab;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final color = active ? accent : textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 8.0 : 6.0,
        vertical: 1,
      ),
      child: Material(
        color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: accent.withValues(alpha: 0.06),
          child: Tooltip(
            message: expanded ? '' : tab.label,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 12.0 : 0,
                vertical: expanded ? 9.0 : 12.0,
              ),
              child: expanded
                  ? Row(
                      children: [
                        Icon(active ? tab.activeIcon : tab.icon,
                            color: color, size: 18),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            tab.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        if (active && !tab.hasSubTabs)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                                color: accent, shape: BoxShape.circle),
                          ),
                        if (tab.hasSubTabs)
                          Icon(
                            active
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 14,
                            color: textSecondary,
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(active ? tab.activeIcon : tab.icon,
                          color: color, size: 20),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSubTabItem extends StatelessWidget {
  const _SidebarSubTabItem({
    required this.sub,
    required this.active,
    required this.onTap,
  });
  final AppSubTab sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final color = active ? accent : textSecondary;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, top: 1, bottom: 1),
      child: Material(
        color: active ? accent.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: accent.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // Connector line
                Container(
                  width: 1,
                  height: 14,
                  color: active
                      ? accent.withValues(alpha: 0.5)
                      : (isDark
                          ? AppColors.border
                          : AppColors.lightBorder),
                  margin: const EdgeInsets.only(right: 10),
                ),
                Icon(sub.icon, color: color, size: 14),
                const Gap(8),
                Text(
                  sub.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSubTabItemCollapsed extends StatelessWidget {
  const _SidebarSubTabItemCollapsed({
    required this.sub,
    required this.active,
    required this.onTap,
  });
  final AppSubTab sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Tooltip(
        message: sub.label,
        child: Material(
          color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 36,
              child: Center(
                child: Icon(
                  sub.icon,
                  size: 15,
                  color: active ? accent : textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarProfileFooter extends StatelessWidget {
  const _SidebarProfileFooter({
    required this.ref,
    required this.expanded,
    required this.active,
    required this.location,
  });
  final WidgetRef ref;
  final bool expanded;
  final bool active;
  final String location;

  @override
  Widget build(BuildContext context) {
    final profileTab = kAppTabs.last; // Profile is always the last tab
    final userAsync = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    final user = userAsync.when(data: (u) => u, loading: () => null, error: (_, __) => null);
    final initial = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : '?';

    // Collapsed sidebar: show avatar icon that navigates to profile
    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Tooltip(
          message: 'Profile',
          child: Material(
            color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => context.go(profileTab.route),
              borderRadius: BorderRadius.circular(10),
              hoverColor: accent.withValues(alpha: 0.06),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: active
                        ? accent.withValues(alpha: 0.25)
                        : accent.withValues(alpha: 0.12),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: accent,
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Expanded sidebar: show user info row + profile sub-tabs when active
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile sub-tabs when active
        if (active)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Column(
              children: [
                for (final sub in profileTab.subTabs)
                  _SidebarSubTabItem(
                    sub: sub,
                    active: location.startsWith(sub.route),
                    onTap: () => context.go(sub.route),
                  ),
                Divider(height: 8, color: borderColor),
              ],
            ),
          ),
        // User identity row (acts as the Profile tab item)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Material(
            color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => context.go(profileTab.route),
              borderRadius: BorderRadius.circular(10),
              hoverColor: accent.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: accent,
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
                            user?.fullName ?? 'Profile',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: active ? accent : null,
                                  fontSize: 11,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 8,
                              color: textSecondary,
                              fontFamily: 'IBMPlexMono',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 13),
                      color: textMuted,
                      tooltip: 'Sign out',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () =>
                          ref.read(authNotifierProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
