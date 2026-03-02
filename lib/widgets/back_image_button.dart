import 'package:flutter/material.dart';

/// Nút Back dùng chung: chỉ ảnh, không chữ. Dùng ảnh assets/images/back.png.
class BackImageButton extends StatelessWidget {
  const BackImageButton({
    super.key,
    required this.onPressed,
    this.size = 48,
    this.padding,
  });

  final VoidCallback? onPressed;
  final double size;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final child = Image.asset(
      'assets/images/back.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    return Padding(
      padding: padding ?? const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: SizedBox(
            width: size + 16,
            height: size + 16,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
