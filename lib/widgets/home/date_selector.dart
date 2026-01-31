import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A date selector widget with month and year dropdowns
class DateSelectorWidget extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const DateSelectorWidget({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth)),
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                onChanged: (val) => onMonthChanged(val!),
                items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(DateFormat('MMM').format(DateTime(0, index + 1))))),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: selectedYear,
                underline: const SizedBox(),
                icon: const SizedBox.shrink(),
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                onChanged: (val) => onYearChanged(val!),
                items: List.generate(5, (index) {
                   int year = DateTime.now().year - 2 + index;
                   return DropdownMenuItem(value: year, child: Text(year.toString()));
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
