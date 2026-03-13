import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/debug_apply.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/game_pause_observer.dart';
import '../../core/services/coin_service.dart';
import '../../core/services/shared_prefs_service.dart';
import '../../inject/injection.dart';
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
  bool _blockedSnackBarVisible = false;
  Timer? _blockedSnackBarResetTimer;

  @override
  void initState() {
    super.initState();
    _loadQuantities();
  }

  @override
  void dispose() {
    _blockedSnackBarResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuantities() async {
    final ids = commonItemList.map((e) => e.effectTypeId).toList();
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

  void _onBlockedItemTap(BuildContext scaffoldContext) {
    if (_blockedSnackBarVisible) return;
    _blockedSnackBarVisible = true;
    _blockedSnackBarResetTimer?.cancel();
    _blockedSnackBarResetTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _blockedSnackBarVisible = false);
    });
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text(L10n.itemBlockedInLevel)),
    );
  }

  void _onUseItem(ItemModel item) {
    final q = _itemQuantities[item.effectTypeId] ?? 0;
    if (q <= 0) return;
    setState(() => _itemQuantities[item.effectTypeId] = q - 1);
    SharedPrefsService.setItemQuantity(item.effectTypeId, q - 1);
    widget.game.useEffect(item.type);
  }

  Future<bool> _onBuyItem(ItemModel item, BuildContext scaffoldContext) async {
    final ok = await CoinService.instance.coinMinus(item.price);
    if (!ok) {
      if (mounted && scaffoldContext.mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(content: Text(L10n.notEnoughCoins)),
        );
      }
      return false;
    }
    final q = _itemQuantities[item.effectTypeId] ?? 0;
    final addCount = shouldApplyDebug ? 10 : 1;
    final next = q + addCount;
    setState(() => _itemQuantities[item.effectTypeId] = next);
    SharedPrefsService.setItemQuantity(item.effectTypeId, next);
    return true;
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
                          'GameOverNoRevive': (ctx, g) => _GameOverNoReviveOverlayWidget(
                            game: g as WormJourneyGame,
                            onGameOverEnd: widget.onGameOverEnd,
                          ),
                          'Victory': (ctx, g) => _VictoryOverlayWidget(
                            game: g as WormJourneyGame,
                            onContinue: widget.onGameOverEnd,
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
                ValueListenableBuilder<bool>(
                  valueListenable: GamePauseObserver.dialogOpen,
                  builder: (context, dialogOpen, child) {
                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 200),
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/bottom_control.png'),
                              fit: BoxFit.fill,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal:0,
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 16, left: 16),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: () {
                                          final blockedIds = game.blockedItemIds;
                                          final sorted = List<ItemModel>.from(commonItemList);
                                          sorted.sort((a, b) {
                                            final aBlocked = blockedIds.contains(a.effectTypeId);
                                            final bBlocked = blockedIds.contains(b.effectTypeId);
                                            if (aBlocked == bBlocked) return 0;
                                            return aBlocked ? 1 : -1;
                                          });
                                          return sorted.map((item) {
                                            final isBlocked = blockedIds.contains(item.effectTypeId);
                                            return _ItemSlot(
                                                item: item,
                                                quantity:
                                                    _itemQuantities[item.effectTypeId] ?? 0,
                                                isBlocked: isBlocked,
                                                onBlockedTap: isBlocked
                                                    ? () => _onBlockedItemTap(dialogContext)
                                                    : null,
                                                onUse: () => _onUseItem(item),
                                                onBuy: () => _onBuyItem(item, dialogContext),
                                                onOpenDialog: () => _openItemDialog(
                                                  dialogContext,
                                                  item,
                                                ),
                                              );
                                            }).toList();
                                        }(),
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
                        if (dialogOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {},
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openItemDialog(BuildContext dialogContext, ItemModel item) {
    GamePauseObserver.dialogOpen.value = true;
    ItemInfoDialog.show(
      dialogContext,
      item: item,
      onBuy: () => _onBuyItem(item, dialogContext),
      onReceive: () => _onUseItem(item),
    );
  }
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    required this.item,
    required this.quantity,
    required this.isBlocked,
    this.onBlockedTap,
    required this.onUse,
    required this.onBuy,
    required this.onOpenDialog,
  });

  final ItemModel item;
  final int quantity;
  final bool isBlocked;
  final VoidCallback? onBlockedTap;
  final VoidCallback onUse;
  final VoidCallback onBuy;
  final VoidCallback onOpenDialog;

  void _onItemTap(BuildContext context) {
    if (isBlocked) {
      onBlockedTap?.call();
      return;
    }
    if (quantity > 0) {
      onUse();
    } else {
      onOpenDialog();
    }
  }

  void _onViewOrBlockTap(BuildContext context) {
    if (isBlocked) {
      onBlockedTap?.call();
      return;
    }
    onOpenDialog();
  }

  static const double _slotWidth = 42;
  static const double _slotHeight = 50;
  static const Color _itemBrown = Color(0xFFB8956A);
  static const Color _viewBrown = Color(0xFFD8C4A8);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: _itemBrown,
          elevation: 1,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: () => _onItemTap(context),
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: _slotWidth,
              height: _slotHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Material(
                    color: _viewBrown,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                    child: InkWell(
                      onTap: () => _onViewOrBlockTap(context),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              L10n.view,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF5D4037),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -7,
          right: -2,
          child: Text(
            L10n.quantityShort(quantity),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isBlocked)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 16,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppConstants.itemBlockedIcon,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
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

/// Overlay Flutter khi chiến thắng: cập nhật level + scene unlock, nút Tiếp tục về màn trước.
class _VictoryOverlayWidget extends StatelessWidget {
  const _VictoryOverlayWidget({
    required this.game,
    this.onContinue,
  });

  final WormJourneyGame game;
  final VoidCallback? onContinue;

  Future<void> _onContinueTap() async {
    final currentMaxLevel = await SharedPrefsService.getMaxLevelIndexUnlock();
    final newLevel = currentMaxLevel < game.level + 1 ? game.level + 1 : currentMaxLevel;
    await SharedPrefsService.setMaxLevelIndexUnlock(newLevel);
    final newSceneFromLevel = ((newLevel - 1) ~/ 5) + 1;
    final currentMaxScene = await SharedPrefsService.getMaxSceneIndexUnlock();
    if (newSceneFromLevel > currentMaxScene) {
      await SharedPrefsService.setMaxSceneIndexUnlock(newSceneFromLevel);
    }
    game.overlays.remove('Victory');
    onContinue?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    return Material(
      color: const Color(0xCC000000),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.victory,
                style: const TextStyle(
                  color: AppColors.gameOverOrange,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: AppColors.textOutlineWhite,
                ),
              ),
              const SizedBox(height: 24),
              GreenButton(
                text: l10n.victoryContinue,
                onPressed: _onContinueTap,
                height: 64,
                width: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay Flutter khi game over: nút Chơi lại dùng [GreenButton] có hiệu ứng scale, icon 🎬 đè góc phải, chữ Kết thúc về màn chọn level.
class _GameOverOverlayWidget extends StatefulWidget {
  const _GameOverOverlayWidget({
    required this.game,
    this.onGameOverEnd,
    this.onWatchAd,
  });

  final WormJourneyGame game;
  final VoidCallback? onGameOverEnd;
  final VoidCallback? onWatchAd;

  @override
  State<_GameOverOverlayWidget> createState() => _GameOverOverlayWidgetState();
}

class _GameOverOverlayWidgetState extends State<_GameOverOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    final game = widget.game;
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
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: GreenButton(
                      text: l10n.gameOverRevive,
                      onPressed: () {
                        game.restart();
                      },
                      height: 64,
                      width: 200,
                    ),
                  ),
                  Positioned(
                    top: -_adBadgeSize / 2 + _adBadgeOverlap,
                    right: -_adBadgeSize / 2 + _adBadgeOverlap,
                    child: GestureDetector(
                      onTap: widget.onWatchAd,
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
                  widget.game.overlays.remove('GameOver');
                  widget.game.overlays.remove('GameOverNoRevive');
                  widget.onGameOverEnd?.call();
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

/// Overlay game over khi đã hồi sinh một lần (hoặc không có nút Hồi sinh): chỉ "Game Over" + "Kết thúc". Debug mode vẫn dùng [GameOver] có nút.
class _GameOverNoReviveOverlayWidget extends StatelessWidget {
  const _GameOverNoReviveOverlayWidget({
    required this.game,
    this.onGameOverEnd,
  });

  final WormJourneyGame game;
  final VoidCallback? onGameOverEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
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
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  game.overlays.remove('GameOver');
                  game.overlays.remove('GameOverNoRevive');
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
