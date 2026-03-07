import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../inject/injection.dart';

/// Màn chọn level: nền full, ô vuông radius mạnh, grid 3 cột; chữ Cảnh 1,2,3... nâu viền trắng.
class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  static const int _levelCount = 12;
  static const int _columns = 3;

  /// Thứ tự level trong grid: 1 2 3 / 4 5 6 / 7 8 9 / 10 11 12 (đọc trái→phải, trên→dưới).
  static List<int> _levelOrder(int count) =>
      List.generate(count, (i) => i + 1);

  @override
  Widget build(BuildContext context) {
    final order = _levelOrder(_levelCount);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/select_level.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _LevelMapGrid(
                      levelCount: _levelCount,
                      order: order,
                      onLevelTap: (level) =>
                          context.push(AppRoutes.game(level)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelMapGrid extends StatelessWidget {
  const _LevelMapGrid({
    required this.levelCount,
    required this.order,
    required this.onLevelTap,
  });

  final int levelCount;
  final List<int> order;
  final void Function(int level) onLevelTap;

  static const double _padding = 24;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final rowCount = (levelCount / LevelSelectionScreen._columns).ceil();
    final colCount = LevelSelectionScreen._columns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - _padding * 2;
        final itemSize = (availableWidth - (colCount - 1) * _gap) / colCount;
        return _buildGridItems(
          context,
          rowCount,
          colCount,
          itemSize,
        );
      },
    );
  }

  Widget _buildGridItems(
    BuildContext context,
    int rowCount,
    int colCount,
    double itemSize,
  ) {
    final l10n = L10n;
    int idx = 0;
    final rows = <Widget>[];
    for (int r = 0; r < rowCount && idx < order.length; r++) {
      if (r > 0) rows.add(SizedBox(height: _gap));
      final cells = <Widget>[];
      for (int c = 0; c < colCount && idx < order.length; c++) {
        if (c > 0) cells.add(SizedBox(width: _gap));
        final level = order[idx++];
        cells.add(
          Expanded(
            child: _LevelBox(
              size: itemSize,
              level: level,
              sceneLabel: l10n.sceneLabel(level),
              onTap: () => onLevelTap(level),
            ),
          ),
        );
      }
      rows.add(
        Row(
          children: cells,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

class _LevelBox extends StatelessWidget {
  const _LevelBox({
    required this.size,
    required this.level,
    required this.sceneLabel,
    required this.onTap,
  });

  final double size;
  final int level;
  final String sceneLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.33,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: size,
              child: Text(
                sceneLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF6D4C41),
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(-1, -1),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(1, -1),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(-1, 1),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(1, 1),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(0, -1),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(0, 1),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(-1, 0),
                    ),
                    Shadow(
                      color: Colors.white,
                      offset: const Offset(1, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
