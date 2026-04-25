import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// BENTO GRID — responsive wrap-based layout
// ══════════════════════════════════════════════════════════════

class BentoCell {
  const BentoCell({required this.child, this.span = 1});
  final Widget child;
  final int span; // 1 = half width (on ≥2 col), 2 = full width
}

class BentoGrid extends StatelessWidget {
  const BentoGrid({
    super.key,
    required this.children,
    this.spacing = 12.0,
  });
  final List<BentoCell> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w >= Breakpoints.desktop ? 3 : w >= Breakpoints.tablet ? 2 : 1;

      if (cols == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i].child,
            ],
          ],
        );
      }

      final cellW = (w - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((cell) {
          final span = cell.span.clamp(1, cols);
          final itemW = cellW * span + spacing * (span - 1);
          return SizedBox(width: itemW, child: cell.child);
        }).toList(),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════
// APP CARD — base card with hover effects
// ══════════════════════════════════════════════════════════════

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.base),
    this.onTap,
    this.color,
    this.borderColor,
    this.height,
    this.accentBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? height;
  final bool accentBorder;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = widget.color ?? (isDark ? AppColors.card : AppColors.lightCard);
    final baseBorder =
        widget.borderColor ?? (isDark ? AppColors.border : AppColors.lightBorder);
    final effectiveBorder = widget.accentBorder
        ? accent.withValues(alpha: 0.5)
        : (_hovered && widget.onTap != null)
            ? accent.withValues(alpha: 0.35)
            : baseBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: effectiveBorder),
          boxShadow: _hovered && widget.onTap != null
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: accent.withValues(alpha: 0.06),
              highlightColor: accent.withValues(alpha: 0.03),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KPI CARD — metric display with icon and optional trend
// ══════════════════════════════════════════════════════════════

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    final up = trendUp ?? true;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                )
              else
                const SizedBox.shrink(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (up ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 10,
                        color: up ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 10,
                          color: up ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CHART CARD — card with title bar + chart area
// ══════════════════════════════════════════════════════════════

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.height = 160,
  });
  final String title;
  final Widget child;
  final Widget? action;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LIST CARD — card wrapping a list of tiles with dividers
// ══════════════════════════════════════════════════════════════

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark ? AppColors.border : AppColors.lightBorder;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.base, Spacing.base, Spacing.base, Spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          Divider(height: 1, color: divider),
          ...children,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION LABEL — reusable row label (replaces SectionHeader)
// ══════════════════════════════════════════════════════════════

class BentoSectionHeader extends StatelessWidget {
  const BentoSectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: textSecondary,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
