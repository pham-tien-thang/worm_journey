import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../gen_l10n/app_localizations.dart';

/// Overlay khi game over: nền mờ + chữ "Game Over" và "Chạm để chơi lại".
/// Thêm vào [camera.viewport] → (0,0) = góc trên-trái viewport, căn giữa chuẩn. [onTap] để chơi lại.
class GameOverOverlay extends PositionComponent with TapCallbacks {
  GameOverOverlay({
    required Vector2 size,
    required this.locale,
    this.onTap,
  }) : super(
          position: Vector2.zero(),
          size: size,
          priority: 1000,
        );

  final Locale locale;
  final VoidCallback? onTap;

  @override
  void onTapDown(TapDownEvent event) {
    onTap?.call();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xCC000000),
    );

    final l10n = AppLocalizations.lookup(locale);
    final title = l10n.gameOver;
    final subtitle = l10n.tapToPlayAgain;
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(centerX - titlePainter.width / 2, centerY - 40),
    );

    final subPainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
      canvas,
      Offset(centerX - subPainter.width / 2, centerY + 10),
    );
  }
}
