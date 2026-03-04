import 'package:flutter/material.dart';

import '../game/game.dart';
import '../components/worm/worm_direction.dart';

/// Bốn nút điều khiển hướng ở cuối màn (không nằm trong vùng game).
class DirectionButtons extends StatelessWidget {
  const DirectionButtons({
    super.key,
    required this.game,
    this.buttonSize = 48,
  });

  final WormJourneyGame game;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(WormDirection.up, Icons.keyboard_arrow_up),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(WormDirection.left, Icons.keyboard_arrow_left),
                SizedBox(width: buttonSize + 8),
                _buildButton(WormDirection.right, Icons.keyboard_arrow_right),
              ],
            ),
            const SizedBox(height: 4),
            _buildButton(WormDirection.down, Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(WormDirection direction, IconData icon) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => game.setDirection(direction),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Icon(icon, size: 28, color: Colors.grey.shade800),
        ),
      ),
    );
  }
}
