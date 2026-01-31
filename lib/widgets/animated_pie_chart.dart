import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedPieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const AnimatedPieChart({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> {
  int touchedIndex = -1;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Trigger animation after build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors for chart
    final List<Color> chartColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber
    ];

    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = widget.data.values.fold(0.0, (sum, val) => sum + val);

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2, // Space between sections
          centerSpaceRadius: 40,
          sections: sortedEntries.asMap().entries.map((entry) {
            final isTouched = entry.key == touchedIndex;
            final fontSize = isTouched ? 25.0 : 12.0;
            final radius = isTouched ? 110.0 : 100.0;
            final percent = (entry.value.value / total) * 100;
            final color = chartColors[entry.key % chartColors.length];

            // Animation: value is 0 until _isPlaying is true
            final value = _isPlaying
                ? entry.value.value
                : 0.001; // Avoid 0 crash in some versions

            return PieChartSectionData(
              color: color,
              value: value,
              title: _isPlaying ? '${percent.toStringAsFixed(0)}%' : '',
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
              ),
              badgeWidget: _isPlaying ? _buildIconBadge(entry.value.key) : null,
              badgePositionPercentageOffset: .98,
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 800), // Smooth grow
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Widget _buildIconBadge(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'grocery':
        icon = Icons.shopping_cart;
        break;
      case 'food':
        icon = Icons.restaurant;
        break;
      case 'transport':
        icon = Icons.directions_car;
        break;
      case 'bills':
        icon = Icons.receipt;
        break;
      case 'entertainment':
        icon = Icons.movie;
        break;
      case 'shopping':
        icon = Icons.shopping_bag;
        break;
      default:
        icon = Icons.category;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [const BoxShadow(blurRadius: 2, color: Colors.black12)],
      ),
      child: Icon(icon, size: 16, color: Colors.black87),
    );
  }
}
