// ══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// All small reusable components used across the app
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';

// ── AppTextField ──────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefix;
  final int? maxLines;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
        ),
        const Gap(5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          enabled: enabled,
          autofocus: autofocus,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixIcon: prefix,
          ),
        ),
      ],
    );
  }
}

// ── AppButton ─────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.textColor,
    this.outlined = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool outlined;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.gold;
    final fg = textColor ?? AppColors.bg;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 13);

    final child = isLoading
        ? SizedBox(
            height: small ? 14 : 18,
            width: small ? 14 : 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? bg : fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 14 : 16),
                const Gap(6),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: bg,
          side: BorderSide(color: bg),
          padding: padding,
          textStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: padding,
        textStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: child,
    );
  }
}

// ── AppCard ───────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    return Material(
      color: AppColors.card,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: (accentColor ?? AppColors.gold).withValues(alpha: 0.08),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: accentColor != null
                  ? accentColor!.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── SectionLabel ──────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color ?? AppColors.gold,
                    letterSpacing: 1.5,
                  ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

// ── CategoryDot ───────────────────────────────────────────────
class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.categoryKey, this.size = 8});
  final String categoryKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(categoryKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
      ),
    );
  }
}

// ── StatCard ──────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.onTap,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const Gap(5),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? AppColors.gold,
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const Gap(3),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}

// ── ProgressBar ───────────────────────────────────────────────
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.backgroundColor,
  });

  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: backgroundColor ?? AppColors.border,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.gold),
        minHeight: height,
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const Gap(12),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          if (action != null && actionLabel != null) ...[
            const Gap(16),
            AppButton(label: actionLabel!, onPressed: action, small: true),
          ],
        ],
      ),
    );
  }
}

// ── DiamondLogo ───────────────────────────────────────────────
class DiamondLogo extends StatelessWidget {
  const DiamondLogo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DiamondPainter(),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void diamond(double radius) {
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy)
        ..close();
      canvas.drawPath(path, paint..color = AppColors.gold.withValues(alpha: paint.color.a));
    }

    paint.color = AppColors.gold;
    diamond(size.width / 2 - 2);
    paint.color = AppColors.gold.withValues(alpha: 0.7);
    diamond(size.width / 2 - 8);
    paint.color = AppColors.gold.withValues(alpha: 0.5);
    diamond(size.width / 2 - 14);

    // Center dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = AppColors.gold.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── LoadingOverlay ─────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.gold),
    );
  }
}

// ── CategoryChip ──────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.categoryKey,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String categoryKey;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(categoryKey);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 150.ms,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : AppColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              CategoryDot(categoryKey: categoryKey, size: 6),
              const Gap(5),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}