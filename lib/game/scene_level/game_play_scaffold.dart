import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/debug_apply.dart';
import '../../core/game_pause_observer.dart';
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

  void _onUseItem(ItemModel item) {
    final q = _itemQuantities[item.effectTypeId] ?? 0;
    if (q <= 0) return;
    setState(() => _itemQuantities[item.effectTypeId] = q - 1);
    SharedPrefsService.setItemQuantity(item.effectTypeId, q - 1);
    widget.game.useEffect(item.type);
  }

  void _onBuyItem(ItemModel item) {
    if (shouldApplyDebug) {
      final q = _itemQuantities[item.effectTypeId] ?? 0;
      final next = q + 10;
      setState(() => _itemQuantities[item.effectTypeId] = next);
      SharedPrefsService.setItemQuantity(item.effectTypeId, next);
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
                                        children: commonItemList
                                            .map((item) => _ItemSlot(
                                                  item: item,
                                                  quantity:
                                                      _itemQuantities[item.effectTypeId] ?? 0,
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
      onBuy: () => _onBuyItem(item),
      onReceive: () => _onUseItem(item),
    );
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
                      onTap: onOpenDialog,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              AppLocalizations.of(context).view,
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
            AppLocalizations.of(context).quantityShort(quantity),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.bold,
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
    final l10n = AppLocalizations.of(context);
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
                      text: l10n.gameOverPlayAgain,
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
