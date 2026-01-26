import 'package:flutter/material.dart';

class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isSelected; // Optional: for toggles if needed

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Theme awareness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // Spacing between buttons
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
