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

  static const List<Color> _chartColors = [
    Color(0xFF667eea),
    Color(0xFFf5576c),
    Color(0xFF4facfe),
    Color(0xFF43e97b),
    Color(0xFFfa709a),
    Color(0xFFfee140),
    Color(0xFF30cfd0),
    Color(0xFFa18cd1),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isPlaying = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = widget.data.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
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
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 52,
                  sections: sortedEntries.asMap().entries.map((entry) {
                    final isTouched = entry.key == touchedIndex;
                    final radius = isTouched ? 90.0 : 80.0;
                    final percent = (entry.value.value / total) * 100;
                    final color =
                        _chartColors[entry.key % _chartColors.length];
                    final value =
                        _isPlaying ? entry.value.value : 0.001;
                    return PieChartSectionData(
                      color: color,
                      value: value,
                      title: _isPlaying
                          ? '${percent.toStringAsFixed(0)}%'
                          : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 13.0 : 11.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 2)
                        ],
                      ),
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCirc,
              ),
              // Center label: show touched category or total
              if (_isPlaying)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: touchedIndex >= 0 &&
                          touchedIndex < sortedEntries.length
                      ? [
                          Text(
                            _getCategoryEmoji(
                                sortedEntries[touchedIndex].key),
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sortedEntries[touchedIndex].key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${((sortedEntries[touchedIndex].value / total) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _chartColors[
                                  touchedIndex % _chartColors.length],
                            ),
                          ),
                        ]
                      : [
                          Text(
                            '${sortedEntries.length}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'categories',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                          ),
                        ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend grid
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: sortedEntries.asMap().entries.map((entry) {
            final color = _chartColors[entry.key % _chartColors.length];
            final isTouched = entry.key == touchedIndex;
            final percent = (entry.value.value / total) * 100;
            return GestureDetector(
              onTap: () => setState(() {
                touchedIndex = isTouched ? -1 : entry.key;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isTouched
                      ? color.withValues(alpha: 0.18)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTouched ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getCategoryEmoji(entry.value.key),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.value.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isTouched
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isTouched
                            ? color
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return '🛒';
      case 'food':
        return '🍽️';
      case 'transport':
        return '🚗';
      case 'bills':
        return '🧾';
      case 'entertainment':
        return '🎬';
      case 'shopping':
        return '🛍️';
      case 'health':
        return '💊';
      case 'education':
        return '📚';
      default:
        return '📦';
    }
  }
}
