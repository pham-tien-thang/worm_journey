/// Model level trong một scene.
class LevelModel {
  const LevelModel({
    required this.id,
    required this.name,
    required this.isUnlock,
  });

  final int id;
  final String name;
  final bool isUnlock;
}

/// Model scene: name, imageLink, indexId, maxAvailableLevel, isUnlock, list level.
class SceneModel {
  const SceneModel({
    required this.indexId,
    required this.name,
    required this.imageLink,
    required this.maxAvailableLevel,
    required this.isUnlock,
    required this.levels,
  });

  final int indexId;
  final String name;
  final String imageLink;
  /// Level id cao nhất được mở trong scene này (theo SharedPrefs max_level_index_unlock).
  final int maxAvailableLevel;
  final bool isUnlock;
  final List<LevelModel> levels;
}

/// Số scene và số level mỗi scene.
const int sceneCount = 12;
const int levelsPerScene = 5;

/// Tạo 12 scene từ [maxSceneIndexUnlock] và [maxLevelIndexUnlock] (đọc từ SharedPrefs).
/// Scene indexId i có levels id từ (i-1)*5+1 đến i*5.
List<SceneModel> buildSceneList({
  required int maxSceneIndexUnlock,
  required int maxLevelIndexUnlock,
}) {
  final list = <SceneModel>[];
  for (var i = 1; i <= sceneCount; i++) {
    final startId = (i - 1) * levelsPerScene + 1;
    final endId = i * levelsPerScene;
    final levels = <LevelModel>[];
    for (var id = startId; id <= endId; id++) {
      levels.add(LevelModel(
        id: id,
        name: 'Chặng $id',
        isUnlock: id <= maxLevelIndexUnlock,
      ));
    }
    /// Level id cao nhất đã mở trong scene này = min(endId, maxLevelIndexUnlock); nếu maxLevel < startId thì 0.
    final maxAvailableLevel = maxLevelIndexUnlock < startId
        ? 0
        : maxLevelIndexUnlock.clamp(startId, endId);
    list.add(SceneModel(
      indexId: i,
      name: 'Scene $i',
      imageLink: '',
      maxAvailableLevel: maxAvailableLevel,
      isUnlock: i <= maxSceneIndexUnlock,
      levels: levels,
    ));
  }
  return list;
}
