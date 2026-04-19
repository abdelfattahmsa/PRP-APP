import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'app_card.dart';

// ══════════════════════════════════════════════════════════════
// LOADING CARD
// ══════════════════════════════════════════════════════════════

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AppCard(
      child: SizedBox(
        height: height,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: accent,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHIMMER ROW — animated placeholder row
// ══════════════════════════════════════════════════════════════

class ShimmerRow extends StatefulWidget {
  const ShimmerRow({super.key, this.height = 56});
  final double height;

  @override
  State<ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<ShimmerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardHover : AppColors.lightCardHover)
              .withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
    this.compact = false,
  });

  final String message;
  final IconData icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final padding = compact ? 24.0 : 48.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 32 : 48, color: textSecondary),
            SizedBox(height: compact ? 8 : 12),
            Text(
              message,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              SizedBox(height: compact ? 12 : 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ERROR STATE
// ══════════════════════════════════════════════════════════════

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ASYNC BUILDER — wraps AsyncValue with loading/error/data states
// ══════════════════════════════════════════════════════════════

class AsyncBuilder<T> extends StatelessWidget {
  const AsyncBuilder({
    super.key,
    required this.value,
    required this.data,
    this.loadingWidget,
    this.errorMessage = 'Failed to load data',
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loadingWidget;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loadingWidget ?? const LoadingCard(),
      error: (e, _) => ErrorState(message: errorMessage, onRetry: onRetry),
      data: data,
    );
  }
}
