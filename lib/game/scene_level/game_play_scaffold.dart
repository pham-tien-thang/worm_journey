import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/debug_apply.dart';
import '../../core/app_colors.dart';
import '../../core/services/shared_prefs_service.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../models/item_model.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_joystick.dart';
import '../../widgets/green_button.dart';
import '../../widgets/item_info_dialog.dart';
import '../game.dart';

/// Scaffold chung cho màn chơi: nhận [game] đã tạo (theo level), hiển thị GameWidget + items + joystick.
/// Mỗi level có màn riêng tạo game rồi truyền vào đây, về sau dễ init map design từng level.
class GamePlayScaffold extends StatefulWidget {
  const GamePlayScaffold({
    super.key,
    required this.game,
    this.onGameOverEnd,
    this.onGameOverWatchAd,
  });

  final WormJourneyGame game;
  final VoidCallback? onGameOverEnd;
  final VoidCallback? onGameOverWatchAd;

  @override
  State<GamePlayScaffold> createState() => _GamePlayScaffoldState();
}

class _GamePlayScaffoldState extends State<GamePlayScaffold> {
  Map<String, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadQuantities();
  }

  Future<void> _loadQuantities() async {
    final ids = commonItemList.map((e) => e.id).toList();
    final map = await SharedPrefsService.getItemQuantities(ids);
    for (final id in ids) {
      final hasKey = await SharedPrefsService.hasItemQuantityKey(id);
      if (!hasKey) {
        map[id] = 10;
        await SharedPrefsService.setItemQuantity(id, 10);
      }
    }
    if (mounted) setState(() => _itemQuantities = map);
  }

  void _onUseItem(ItemModel item) {
    final q = _itemQuantities[item.id] ?? 0;
    if (q <= 0) return;
    setState(() => _itemQuantities[item.id] = q - 1);
    SharedPrefsService.setItemQuantity(item.id, q - 1);
    switch (item.effect) {
      case ItemEffect.evilMode:
        widget.game.triggerDevilModeByItem();
        break;
      case ItemEffect.none:
        break;
    }
  }

  void _onBuyItem(ItemModel item) {
    if (shouldApplyDebug) {
      final q = _itemQuantities[item.id] ?? 0;
      final next = q + 10;
      setState(() => _itemQuantities[item.id] = next);
      SharedPrefsService.setItemQuantity(item.id, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Builder(
      builder: (dialogContext) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget(
                        game: game,
                        overlayBuilderMap: {
                          'GameOver': (ctx, g) => _GameOverOverlayWidget(
                            game: g as WormJourneyGame,
                            onGameOverEnd: widget.onGameOverEnd,
                            onWatchAd: widget.onGameOverWatchAd,
                          ),
                        },
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: GameHud(game: game),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    // image: DecorationImage(
                    //   image: const AssetImage('assets/images/bottom_joystick.png'),
                    //   fit: BoxFit.cover,
                    //   alignment: Alignment.topCenter,
                    // ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 12,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: commonItemList
                                    .map((item) => _ItemSlot(
                                          item: item,
                                          quantity:
                                              _itemQuantities[item.id] ?? 0,
                                          onUse: () => _onUseItem(item),
                                          onBuy: () => _onBuyItem(item),
                                          onOpenDialog: () => _openItemDialog(
                                            dialogContext,
                                            item,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GameJoystick(
                          game: game,
                          size: 160,
                          baseRadius: 64,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openItemDialog(BuildContext dialogContext, ItemModel item) {
    widget.game.setPaused(true);
    ItemInfoDialog.show(
      dialogContext,
      item: item,
      onBuy: () => _onBuyItem(item),
      onReceive: () => _onUseItem(item),
    ).then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        widget.game.setPaused(false);
      });
    });
  }
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    required this.item,
    required this.quantity,
    required this.onUse,
    required this.onBuy,
    required this.onOpenDialog,
  });

  final ItemModel item;
  final int quantity;
  final VoidCallback onUse;
  final VoidCallback onBuy;
  final VoidCallback onOpenDialog;

  void _onItemTap(BuildContext context) {
    if (quantity > 0) {
      onUse();
    } else {
      onOpenDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white,
              elevation: 1,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () => _onItemTap(context),
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Text(
                    item.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Text(
                AppLocalizations.of(context).quantityShort(quantity),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onOpenDialog,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                AppLocalizations.of(context).view,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kích thước badge quảng cáo đè góc phải nút Chơi lại.
const double _adBadgeSize = 36;
const double _adBadgeOverlap = 10;

/// Overlay Flutter khi game over: nút Chơi lại dùng [GreenButton], icon 🎬 đè góc phải, chữ Kết thúc về màn chọn level.
class _GameOverOverlayWidget extends StatelessWidget {
  const _GameOverOverlayWidget({
    required this.game,
    this.onGameOverEnd,
    this.onWatchAd,
  });

  final WormJourneyGame game;
  final VoidCallback? onGameOverEnd;
  final VoidCallback? onWatchAd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xCC000000),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.gameOver,
                style: const TextStyle(
                  color: AppColors.gameOverOrange,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: AppColors.textOutlineWhite,
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GreenButton(
                    text: l10n.gameOverPlayAgain,
                    onPressed: () {
                      game.restart();
                    },
                    height: 64,
                    width: 200,
                  ),
                  Positioned(
                    top: -_adBadgeSize / 2 + _adBadgeOverlap,
                    right: -_adBadgeSize / 2 + _adBadgeOverlap,
                    child: GestureDetector(
                      onTap: onWatchAd,
                      child: Container(
                        width: _adBadgeSize,
                        height: _adBadgeSize,
                        decoration: BoxDecoration(
                          color: AppColors.gameOverOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '🎬',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  game.overlays.remove('GameOver');
                  onGameOverEnd?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.gameOverEnd,
                    style: const TextStyle(
                      color: AppColors.gameOverOrange,
                      fontSize: 18,
                      shadows: AppColors.textOutlineWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
