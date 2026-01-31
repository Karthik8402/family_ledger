import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedBarChart extends StatefulWidget {
  final Map<int, double> dailyTotals;
  final double maxSpend;
  final bool isDark;
  final Color primaryColor;

  const AnimatedBarChart({
    super.key,
    required this.dailyTotals,
    required this.maxSpend,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: widget.maxSpend * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${group.x.toInt()}\n₹${rod.toY.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 && value > 0 && value <= 31) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value.toInt().toString(),
                        style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: widget.dailyTotals.entries.map((entry) {
          final isHigh = entry.value > (widget.maxSpend * 0.8);
          // Animation: value is 0 until _isPlaying is true
          final yValue = _isPlaying ? entry.value : 0.0;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: yValue,
                color: isHigh ? Colors.redAccent : widget.primaryColor,
                width: 6,
                borderRadius: BorderRadius.circular(2),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: widget.maxSpend * 1.2,
                    color:
                        widget.isDark ? Colors.white10 : Colors.grey.shade100),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 800), // Smooth grow
      curve: Curves.easeOutQuart,
    );
  }
}
