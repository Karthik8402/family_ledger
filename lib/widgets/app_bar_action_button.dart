import 'package:flutter/material.dart';

/// A modern, animated app bar action button with theme-aware styling
/// Features: scale animation on press, subtle hover glow, icon color transitions
class AppBarActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isActive;
  final Color? activeColor;
  final bool showBadge;
  final String? badgeText;

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
    this.activeColor,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  State<AppBarActionButton> createState() => _AppBarActionButtonState();
}

class _AppBarActionButtonState extends State<AppBarActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.activeColor ?? theme.colorScheme.primary;

    // Theme-aware colors
    final bgColor = widget.isActive
        ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.12)
        : (_isHovered
            ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)));

    final borderColor = widget.isActive
        ? primaryColor.withValues(alpha: 0.3)
        : (_isHovered
            ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1))
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)));

    final iconColor = widget.isActive
        ? primaryColor
        : (_isHovered
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.75));

    final glowColor = widget.isActive
        ? primaryColor.withValues(alpha: 0.25)
        : primaryColor.withValues(alpha: _isHovered ? 0.15 : 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onPressed,
                child: Tooltip(
                  message: widget.tooltip,
                  preferBelow: false,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        if (_isHovered || widget.isActive)
                          BoxShadow(
                            color: glowColor,
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(opacity: animation, child: child),
                            );
                          },
                          child: Icon(
                            widget.icon,
                            key: ValueKey(widget.icon),
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                        // Badge indicator
                        if (widget.showBadge)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 8,
                                minHeight: 8,
                              ),
                              child: widget.badgeText != null
                                  ? Text(
                                      widget.badgeText!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Specialized theme toggle button with animated sun/moon transition
class ThemeToggleButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggleButton({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));


    if (widget.isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ThemeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      if (widget.isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    const sunColor = Color(0xFFFFB300);
    const moonColor = Color(0xFF90CAF9);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: Tooltip(
          message: widget.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          preferBelow: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final color = Color.lerp(sunColor, moonColor, _rotationAnimation.value)!;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDark
                        ? [
                            const Color(0xFF1a1a2e).withValues(alpha: _isHovered ? 0.9 : 0.7),
                            const Color(0xFF16213e).withValues(alpha: _isHovered ? 0.9 : 0.7),
                          ]
                        : [
                            const Color(0xFFFFF8E1).withValues(alpha: _isHovered ? 0.9 : 0.7),
                            const Color(0xFFFFECB3).withValues(alpha: _isHovered ? 0.9 : 0.7),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: _isHovered ? 0.5 : 0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                  ],
                ),
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 3.14159 * 2,
                  child: Transform.scale(
                    scale: _isHovered ? 1.1 : 1.0,
                    child: Icon(
                      widget.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 20,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
