import 'package:flutter/material.dart';

/// A stat card widget for displaying income/expense totals
class StatCardWidget extends StatelessWidget {
  final String title;
  final double sharedAmount;
  final double privateAmount;
  final Color color;
  final IconData icon;

  const StatCardWidget({
    super.key,
    required this.title,
    required this.sharedAmount,
    required this.privateAmount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹${sharedAmount.toStringAsFixed(2)}', 
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Shared (Family)',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
          ),
          
          if (privateAmount > 0) ...[
            const SizedBox(height: 20),
            Divider(color: theme.dividerColor.withOpacity(0.5)),
            const SizedBox(height: 12),
             Row(
              children: [
                Icon(Icons.person, color: color.withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text(
                  'My Private: ₹${privateAmount.toStringAsFixed(2)}', 
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
