import 'package:flutter/material.dart';

/// Nút dùng chung: label, color, border, radius, isEnabled.
/// Radius mặc định bo tròn hết cỡ. Border mặc định không.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.side = BorderSide.none,
    this.borderRadius,
    this.isEnabled = true,
  });

  final Widget label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide side;
  /// Mặc định bo tròn hết cỡ (pill shape).
  final BorderRadius? borderRadius;
  final bool isEnabled;

  static BorderRadius get _defaultRadius => BorderRadius.circular(999);

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? _defaultRadius;
    final theme = Theme.of(context);
    return FilledButton(
      onPressed: isEnabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: isEnabled
            ? (backgroundColor ?? theme.colorScheme.primary)
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: isEnabled
            ? (foregroundColor ?? theme.colorScheme.onPrimary)
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        side: side,
        shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
      ),
      child: label,
    );
  }
}
