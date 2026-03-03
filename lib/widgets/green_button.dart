import 'package:flutter/material.dart';

/// Nút dùng ảnh nền xanh (button_main.png), text stack lên trên.
class GreenButton extends StatelessWidget {
  const GreenButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 56,
    this.width,
  });

  final String text;
  final VoidCallback onPressed;
  final double height;
  /// Nếu set, nút kéo dài theo chiều ngang (ảnh stretch theo width).
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/button_main.png',
                fit: width != null ? BoxFit.fill : BoxFit.contain,
                width: width,
                height: height,
              ),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
