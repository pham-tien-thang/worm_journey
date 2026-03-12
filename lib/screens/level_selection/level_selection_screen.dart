import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/services/shared_prefs_service.dart' show SharedPrefsService, unlockNotifier;
import '../../gen_l10n/app_localizations.dart';
import '../../inject/injection.dart';
import '../../models/scene_model.dart';

/// Màn chọn level trong một scene: hiển thị list level của scene (5 level), unlock theo SharedPrefs.
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key, required this.sceneIndex});

  final int sceneIndex;

  static const int _columns = 3;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  SceneModel? _scene;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScene();
    unlockNotifier.addListener(_onUnlockChanged);
  }

  @override
  void dispose() {
    unlockNotifier.removeListener(_onUnlockChanged);
    super.dispose();
  }

  void _onUnlockChanged() => _loadScene();

  Future<void> _loadScene() async {
    final maxScene = await SharedPrefsService.getMaxSceneIndexUnlock();
    final maxLevel = await SharedPrefsService.getMaxLevelIndexUnlock();
    final scenes = buildSceneList(
      maxSceneIndexUnlock: maxScene,
      maxLevelIndexUnlock: maxLevel,
    );
    final index = (widget.sceneIndex - 1).clamp(0, scenes.length - 1);
    if (!mounted) return;
    setState(() {
      _scene = index < scenes.length ? scenes[index] : null;
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
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _scene == null
                          ? const Center(child: Text('Scene not found'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _LevelGrid(
                                scene: _scene!,
                                onLevelTap: (level) =>
                                    context.push(AppRoutes.game(level.id)),
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

class _LevelGrid extends StatelessWidget {
  const _LevelGrid({
    required this.scene,
    required this.onLevelTap,
  });

  final SceneModel scene;
  final void Function(LevelModel level) onLevelTap;

  static const double _padding = 24;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    final levels = scene.levels;
    const colCount = LevelSelectionScreen._columns;
    final rowCount = (levels.length / colCount).ceil();
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
                        child: _buildLevelBox(
                          context,
                          itemSize,
                          levels.length > r * colCount + c
                              ? levels[r * colCount + c]
                              : null,
                          l10n,
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

  Widget _buildLevelBox(
    BuildContext context,
    double size,
    LevelModel? level,
    AppLocalizations l10n,
  ) {
    if (level == null) return const SizedBox.shrink();
    final radius = size * 0.28;
    final canTap = level.isUnlock;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? () => onLevelTap(level) : null,
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
                      '${level.id}',
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
                    l10n.stageLabel(level.id),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF6D4C41),
                      fontSize: size * 0.16,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(color: Colors.white, offset: Offset(-1, -1)),
                        Shadow(color: Colors.white, offset: Offset(1, -1)),
                        Shadow(color: Colors.white, offset: Offset(-1, 1)),
                        Shadow(color: Colors.white, offset: Offset(1, 1)),
                        Shadow(color: Colors.white, offset: Offset(0, -1)),
                        Shadow(color: Colors.white, offset: Offset(0, 1)),
                        Shadow(color: Colors.white, offset: Offset(-1, 0)),
                        Shadow(color: Colors.white, offset: Offset(1, 0)),
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
