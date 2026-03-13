import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/game_pause_observer.dart';
import '../../core/services/coin_service.dart';
import '../../inject/injection.dart';
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
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_game.overlays.isActive('Victory')) {
          _showVictoryExitWarning();
          return;
        }
        _showExitWarning();
      },
      child: GamePlayScaffold(
        game: _game,
        onGameOverEnd: () => context.pop(),
      ),
    );
  }
}
