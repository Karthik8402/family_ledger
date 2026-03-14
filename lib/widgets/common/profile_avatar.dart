import 'package:flutter/material.dart';

/// A profile avatar widget that gracefully handles image load errors.
///
/// On first image load error (e.g., 429 rate limit), it permanently
/// switches to a fallback initial-based avatar to prevent infinite retry loops.
class ProfileAvatar extends StatefulWidget {
  final String? url;
  final String name;
  final double radius;
  final Color primaryColor;
  final double? fontSize;

  const ProfileAvatar({
    super.key,
    required this.url,
    required this.name,
    required this.primaryColor,
    this.radius = 20,
    this.fontSize,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _hasError = false;

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset error state if URL actually changes
    if (oldWidget.url != widget.url) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;

    // Show fallback immediately if no URL, empty URL, or previous error
    if (_hasError || widget.url == null || widget.url!.isEmpty) {
      return _buildFallback(size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.primaryColor.withValues(alpha: 0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        widget.url!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          // Schedule state update to prevent rebuild during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() => _hasError = true);
            }
          });
          // Return fallback immediately
          return _buildFallback(size);
        },
      ),
    );
  }

  Widget _buildFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.primaryColor.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: widget.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize ?? (widget.radius * 0.8),
        ),
      ),
    );
  }
}
