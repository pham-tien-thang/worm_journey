import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/services/shared_prefs_service.dart' show SharedPrefsService, unlockNotifier;
import '../../models/scene_model.dart';
import '../../widgets/coin_hud.dart';

/// Màn chọn scene: 12 scene, mỗi scene có list level (indexId*1 đến indexId*5). Unlock theo SharedPrefs.
class SceneSelectionScreen extends StatefulWidget {
  const SceneSelectionScreen({super.key});

  static const int _columns = 3;

  @override
  State<SceneSelectionScreen> createState() => _SceneSelectionScreenState();
}

class _SceneSelectionScreenState extends State<SceneSelectionScreen> {
  List<SceneModel> _scenes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScenes();
    unlockNotifier.addListener(_onUnlockChanged);
  }

  @override
  void dispose() {
    unlockNotifier.removeListener(_onUnlockChanged);
    super.dispose();
  }

  void _onUnlockChanged() => _loadScenes();

  Future<void> _loadScenes() async {
    final maxScene = await SharedPrefsService.getMaxSceneIndexUnlock();
    final maxLevel = await SharedPrefsService.getMaxLevelIndexUnlock();
    if (!mounted) return;
    setState(() {
      _scenes = buildSceneList(
        maxSceneIndexUnlock: maxScene,
        maxLevelIndexUnlock: maxLevel,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        weight: 100,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white70,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: CoinHud(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _SceneGrid(
                            scenes: _scenes,
                            onSceneTap: (scene) =>
                                context.push(AppRoutes.sceneLevels(scene.indexId)),
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

class _SceneGrid extends StatelessWidget {
  const _SceneGrid({
    required this.scenes,
    required this.onSceneTap,
  });

  final List<SceneModel> scenes;
  final void Function(SceneModel scene) onSceneTap;

  static const double _padding = 24;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    const colCount = SceneSelectionScreen._columns;
    final rowCount = (scenes.length / colCount).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - _padding * 2;
        final itemSize = (availableWidth - (colCount - 1) * _gap) / colCount;
        return Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rowCount; r++) ...[
                if (r > 0) const SizedBox(height: _gap),
                Row(
                  children: [
                    for (var c = 0; c < colCount; c++) ...[
                      if (c > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: _buildSceneBox(
                          context,
                          itemSize,
                          scenes.length > r * colCount + c
                              ? scenes[r * colCount + c]
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSceneBox(BuildContext context, double size, SceneModel? scene) {
    if (scene == null) return const SizedBox.shrink();
    final radius = size * 0.28;
    final canTap = scene.isUnlock;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? () => onSceneTap(scene) : null,
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: canTap
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
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
                      '${scene.indexId}',
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
                    scene.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF6D4C41),
                      fontSize: size * 0.16,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(-1, -1),
                        ),
                        Shadow(
                          color: Colors.white,
                          offset: Offset(1, -1),
                        ),
                        Shadow(
                          color: Colors.white,
                          offset: Offset(-1, 1),
                        ),
                        Shadow(
                          color: Colors.white,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!canTap)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
