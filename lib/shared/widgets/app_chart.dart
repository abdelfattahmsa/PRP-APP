import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// APP LINE CHART — smooth bezier line chart via fl_chart
// ══════════════════════════════════════════════════════════════

class AppLineChart extends StatelessWidget {
  const AppLineChart({
    super.key,
    required this.data,
    this.labels,
    this.color,
    this.showGradient = true,
    this.showGrid = true,
    this.minY = 0,
    this.maxY,
    this.curved = true,
  });

  final List<double> data;
  final List<String>? labels;
  final Color? color;
  final bool showGradient;
  final bool showGrid;
  final double minY;
  final double? maxY;
  final bool curved;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = color ?? Theme.of(context).colorScheme.primary;
    final gridColor = isDark
        ? AppColors.border.withValues(alpha: 0.5)
        : AppColors.lightBorder;
    final effectiveMaxY = maxY ?? (data.reduce(max) * 1.25).ceilToDouble();
    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: curved,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                radius: 3,
                color: lineColor,
                strokeWidth: 1.5,
                strokeColor: isDark ? AppColors.surface : AppColors.lightSurface,
              ),
            ),
            belowBarData: showGradient
                ? BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        lineColor.withValues(alpha: 0.18),
                        lineColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : BarAreaData(show: false),
          ),
        ],
        gridData: showGrid
            ? FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: effectiveMaxY / 4,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: gridColor, strokeWidth: 1),
              )
            : const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: labels != null && labels!.isNotEmpty,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: labels != null && labels!.isNotEmpty,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                final lbls = labels ?? [];
                if (i < 0 || i >= lbls.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lbls[i],
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY,
        maxY: effectiveMaxY,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// APP BAR CHART — vertical bar chart
// ══════════════════════════════════════════════════════════════

class AppBarChart extends StatelessWidget {
  const AppBarChart({
    super.key,
    required this.data,
    this.labels,
    this.colors,
    this.barWidth = 14.0,
    this.maxY,
  });

  final List<double> data;
  final List<String>? labels;
  final List<Color>? colors;
  final double barWidth;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final effectiveMaxY =
        maxY ?? (data.isEmpty ? 100 : data.reduce(max) * 1.3).ceilToDouble();

    return BarChart(
      BarChartData(
        barGroups: List.generate(data.length, (i) {
          final barColor = colors != null && i < colors!.length
              ? colors![i]
              : accent;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: barColor,
                width: barWidth,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: effectiveMaxY,
                  color: isDark
                      ? AppColors.border.withValues(alpha: 0.3)
                      : AppColors.lightBorder.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        }),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: labels != null && labels!.isNotEmpty,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: labels != null && labels!.isNotEmpty,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                final lbls = labels ?? [];
                if (i < 0 || i >= lbls.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    lbls[i],
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        maxY: effectiveMaxY,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// APP RING CHART — donut / progress ring
// ══════════════════════════════════════════════════════════════

class AppRingChart extends StatelessWidget {
  const AppRingChart({
    super.key,
    required this.value,
    required this.total,
    this.color,
    this.size = 80,
    this.strokeWidth = 8,
    this.label,
  });

  final double value;
  final double total;
  final Color? color;
  final double size;
  final double strokeWidth;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? Theme.of(context).colorScheme.primary;
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    final bg =
        isDark ? AppColors.border : AppColors.lightBorder.withValues(alpha: 0.6);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: strokeWidth,
            backgroundColor: bg,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
          if (label != null)
            Text(
              label!,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: size * 0.18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
