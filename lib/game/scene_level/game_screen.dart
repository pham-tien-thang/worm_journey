import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/game_pause_observer.dart';
import '../../core/services/coin_service.dart';
import '../../inject/injection.dart';
import '../../models/scene_model.dart';
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
  bool _showJoystickCoach = false;

  bool get _isLastLevelOfScene =>
      widget.level > 0 && widget.level % levelsPerScene == 0;

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
    final guideText =
        locale.languageCode == 'vi'
            ? (guideVi.isNotEmpty ? guideVi : guideEn)
            : (guideEn.isNotEmpty ? guideEn : guideVi);
    if (guideText.isEmpty) return;
    GamePauseObserver.dialogOpen.value = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => GuideGameDialog(
            guideText: guideText,
            onUnderstood: () {
              Navigator.of(context).pop();
              if (widget.level == 1) {
                _game.setPaused(true);
              }
            },
          ),
    );
    if (!mounted) return;
    GamePauseObserver.dialogOpen.value = false;
    if (widget.level == 1) {
      _game.setPaused(true);
      setState(() => _showJoystickCoach = true);
    } else {
      _game.dismissGuide();
    }
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
    GamePauseObserver.dialogOpen.value = false;
    if (confirm == true) {
      context.pop();
    }
  }

  /// Thoát victory: đã thắng nên chỉ show warning mất thưởng, không show "end game".
  Future<void> _showVictoryExitWarning() async {
    GamePauseObserver.dialogOpen.value = true;
    final l10n = L10n;
    final reward = _game.victoryExitReward;
    final confirm = await ExitGameDialog.show(
      context,
      message: l10n.victoryExitLoseRewardWarning,
      exitRewardAmount: reward,
    );
    if (!mounted) return;
    GamePauseObserver.dialogOpen.value = false;
    if (confirm != true) return;
    if (reward != null) await CoinService.instance.coinPlus(reward);
    await _game.performVictoryUnlockAndDismiss();
    _returnAfterVictory();
  }

  void _returnAfterVictory() {
    if (!mounted) return;
    if (_isLastLevelOfScene) {
      context.go(AppRoutes.play);
      return;
    }
    context.pop();
  }

  void _handleExitRequest() {
    if (_game.overlays.isActive('Victory')) {
      _showVictoryExitWarning();
      return;
    }
    _showExitWarning();
  }

  @override
  Widget build(BuildContext context) {
    final content = GamePlayScaffold(
      game: _game,
      showJoystickCoach: _showJoystickCoach,
      onJoystickCoachFinished: () {
        if (mounted) setState(() => _showJoystickCoach = false);
        _game.dismissGuide();
      },
      onExitRequested: _handleExitRequest,
      onGameOverEnd: () => context.pop(),
      onVictoryEnd: _returnAfterVictory,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExitRequest();
      },
      child: content,
    );
  }
}
