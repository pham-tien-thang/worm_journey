import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/game_pause_observer.dart';
import '../../widgets/exit_game_dialog.dart';
import '../../widgets/guide_game_dialog.dart';
import 'game_play_scaffold.dart';
import '../game.dart';

/// Màn game theo level (giữ để tương thích). Ưu tiên dùng [GameLevel1Screen], [GameLevel2Screen], [GameLevel3Screen] để init map design từng level.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.level = 1});

  final int level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WormJourneyGame _game;

  @override
  void initState() {
    super.initState();
    _game = WormJourneyGame(
      level: widget.level,
      onGuideLoaded: (guideVi, guideEn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showGuideDialog(guideVi, guideEn);
        });
      },
    );
    GamePauseObserver.onPauseChange = (paused) => _game.setPaused(paused);
    GamePauseObserver.dialogOpen.value = false;
  }

  Future<void> _showGuideDialog(String guideVi, String guideEn) async {
    final locale = Localizations.localeOf(context);
    final guideText = locale.languageCode == 'vi'
        ? (guideVi.isNotEmpty ? guideVi : guideEn)
        : (guideEn.isNotEmpty ? guideEn : guideVi);
    if (guideText.isEmpty) return;
    GamePauseObserver.dialogOpen.value = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GuideGameDialog(
        guideText: guideText,
        onUnderstood: () {
          Navigator.of(context).pop();
          _game.dismissGuide();
        },
      ),
    );
    if (mounted) GamePauseObserver.dialogOpen.value = false;
  }

  @override
  void dispose() {
    GamePauseObserver.onPauseChange = null;
    super.dispose();
  }

  Future<void> _showExitWarning() async {
    GamePauseObserver.dialogOpen.value = true;
    final confirm = await ExitGameDialog.show(context);
    if (!mounted) return;
    if (confirm == true) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitWarning();
      },
      child: GamePlayScaffold(
        game: _game,
        onGameOverEnd: () => context.pop(),
      ),
    );
  }
}
