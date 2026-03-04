import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../gen_l10n/app_localizations.dart';

/// Overlay khi game over: nền mờ + "Game Over", nút Chơi lại (vẽ bằng code), icon 🎬 đè góc phải, chữ Kết thúc.
class GameOverOverlay extends PositionComponent with TapCallbacks {
  GameOverOverlay({
    required Vector2 size,
    required this.locale,
    this.onTap,
    this.onEnd,
    this.onWatchAd,
  }) : super(
          position: Vector2.zero(),
          size: size,
          priority: 1000,
        );

  final Locale locale;
  final VoidCallback? onTap;
  final VoidCallback? onEnd;
  final VoidCallback? onWatchAd;

  /// Cỡ nút: giống main menu, scale thêm chiều cao.
  static const double _buttonWidth = 200;
  static const double _buttonHeight = 64;
  static const double _adBadgeSize = 36;
  static const double _adBadgeOverlap = 10;

  Rect? _playAgainRect;
  Rect? _adBadgeRect;
  Rect? _endTextRect;

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;
    if (_adBadgeRect != null && _adBadgeRect!.contains(Offset(pos.x, pos.y))) {
      onWatchAd?.call();
      return;
    }
    if (_playAgainRect != null && _playAgainRect!.contains(Offset(pos.x, pos.y))) {
      onTap?.call();
      return;
    }
    if (_endTextRect != null && _endTextRect!.contains(Offset(pos.x, pos.y))) {
      onEnd?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xCC000000),
    );

    final l10n = AppLocalizations.lookup(locale);
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Title "Game Over"
    final titlePainter = TextPainter(
      text: TextSpan(
        text: l10n.gameOver,
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
      Offset(centerX - titlePainter.width / 2, centerY - 80),
    );

    // Nút "Chơi lại" (vẽ rounded rect, không load asset)
    final buttonLeft = centerX - _buttonWidth / 2;
    final buttonTop = centerY - 24;
    _playAgainRect = Rect.fromLTWH(buttonLeft, buttonTop, _buttonWidth, _buttonHeight);

    final buttonRRect = RRect.fromRectAndRadius(
      _playAgainRect!,
      const Radius.circular(28),
    );
    canvas.drawRRect(
      buttonRRect,
      Paint()..color = const Color(0xFFE91E8C),
    );
    canvas.drawRRect(
      buttonRRect,
      Paint()
        ..color = const Color(0xFFC2185B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final playAgainPainter = TextPainter(
      text: TextSpan(
        text: l10n.gameOverPlayAgain,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    playAgainPainter.layout();
    playAgainPainter.paint(
      canvas,
      Offset(
        centerX - playAgainPainter.width / 2,
        buttonTop + (_buttonHeight - playAgainPainter.height) / 2,
      ),
    );

    // Icon quảng cáo 🎬 đè góc phải nút
    final adBadgeLeft = buttonLeft + _buttonWidth - _adBadgeSize + _adBadgeOverlap;
    final adBadgeTop = buttonTop - _adBadgeSize / 2 + _adBadgeOverlap;
    _adBadgeRect = Rect.fromLTWH(adBadgeLeft, adBadgeTop, _adBadgeSize, _adBadgeSize);

    canvas.drawCircle(
      Offset(_adBadgeRect!.center.dx, _adBadgeRect!.center.dy),
      _adBadgeSize / 2,
      Paint()..color = const Color(0xFFFF9800),
    );
    canvas.drawCircle(
      Offset(_adBadgeRect!.center.dx, _adBadgeRect!.center.dy),
      _adBadgeSize / 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final adPainter = TextPainter(
      text: const TextSpan(
        text: '🎬',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Apple Color Emoji',
          fontFamilyFallback: ['Noto Color Emoji', 'Segoe UI Emoji'],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    adPainter.layout();
    adPainter.paint(
      canvas,
      Offset(
        _adBadgeRect!.center.dx - adPainter.width / 2,
        _adBadgeRect!.center.dy - adPainter.height / 2,
      ),
    );

    // Chữ "Kết thúc" bên dưới nút
    final endPainter = TextPainter(
      text: TextSpan(
        text: l10n.gameOverEnd,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    endPainter.layout();
    final endY = buttonTop + _buttonHeight + 16;
    endPainter.paint(
      canvas,
      Offset(centerX - endPainter.width / 2, endY),
    );
    _endTextRect = Rect.fromLTWH(
      centerX - endPainter.width / 2,
      endY,
      endPainter.width,
      endPainter.height,
    );
  }
}
