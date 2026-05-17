import 'dart:async';
import 'dart:math';

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
import '../../widgets/exit_game_dialog.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_joystick.dart';
import '../../widgets/green_button.dart';
import '../../widgets/item_info_dialog.dart';
import '../../widgets/lucky_wheel.dart';
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

/// Hằng số thưởng chiến thắng: base 20, thưởng level = base*level, thưởng thời gian = (remaining/totalTime)*base.
const int _victoryRewardBase = 20;
/// Tốc độ quay kim wheel; claim nhảy random tỉ lệ thuận (cùng tốc độ chậm/nhanh).
const double _victoryWheelSpeed = 0.38;

/// Overlay Flutter khi chiến thắng: nút Claim nhảy random số (1.5x/2x/3x) + icon đồng xu, Exit chỉ "Thoát xx 🪙", bấm Exit hiện warning. Thiết kế giống dialog hồi sinh.
class _VictoryOverlayWidget extends StatefulWidget {
  const _VictoryOverlayWidget({
    required this.game,
    this.onContinue,
  });

  final WormJourneyGame game;
  final VoidCallback? onContinue;

  @override
  State<_VictoryOverlayWidget> createState() => _VictoryOverlayWidgetState();
}

class _VictoryOverlayWidgetState extends State<_VictoryOverlayWidget>
    with TickerProviderStateMixin {
  late final AnimationController _statsController;
  late final AnimationController _claimEffectController;
  late final int _totalReward;
  late final int _levelReward;
  late final int _timeReward;
  late final int _coinReward;
  double _pointerAngle = -pi / 2;
  bool _isClaiming = false;
  int _claimAmount = 0;
  Offset? _burstOrigin;
  final GlobalKey _wheelKey = GlobalKey();

  int get _claimSegmentIndex => LuckyWheel.segmentIndexFromAngle(_pointerAngle);
  String get _claimMultiplierLabel => LuckyWheel.labelForSegmentIndex(_claimSegmentIndex);

  int get _displayedClaimAmount {
    final idx = LuckyWheel.segmentIndexFromAngle(_pointerAngle);
    final mul = LuckyWheel.segmentMultipliers[idx];
    final value = _totalReward * mul;
    return value.ceil();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamePauseObserver.dialogOpen.value = true;
    });
    final level = widget.game.level;
    final timeLimit = widget.game.timeLimitSeconds;
    final remaining = widget.game.hudData.timeRemainingSeconds;
    _levelReward = _victoryRewardBase * level;
    final timeRatio = timeLimit > 0 ? (remaining / timeLimit).clamp(0.0, 1.0) : 0.0;
    _timeReward = (timeRatio * _victoryRewardBase).round();
    _coinReward = widget.game.coinsCollectedThisRun * 1;
    _totalReward = _levelReward + _timeReward + _coinReward;
    widget.game.setVictoryExitReward(_totalReward);

    const totalStatsDuration = Duration(milliseconds: 2400);
    _statsController = AnimationController(
      vsync: this,
      duration: totalStatsDuration,
    )..forward();

    _claimEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _claimEffectController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isClaiming && mounted) {
        CoinService.instance.coinPlus(_claimAmount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.victoryRewardReceived(_claimAmount, AppConstants.coinIcon),
            ),
          ),
        );
        _unlockAndDismiss();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamePauseObserver.dialogOpen.value = false;
    });
    _statsController.dispose();
    _claimEffectController.dispose();
    super.dispose();
  }

  int _displayedForPhase(double progress, int phase) {
    const step = 1 / 3;
    final phaseStart = phase * step;
    final phaseEnd = (phase + 1) * step;
    if (progress <= phaseStart) return 0;
    if (progress >= phaseEnd) {
      switch (phase) {
        case 0:
          return _levelReward;
        case 1:
          return _timeReward;
        case 2:
          return _coinReward;
        default:
          return 0;
      }
    }
    final t = (progress - phaseStart) / (phaseEnd - phaseStart);
    final target = phase == 0 ? _levelReward : (phase == 1 ? _timeReward : _coinReward);
    return (t * target).round();
  }

  Future<void> _unlockAndDismiss() async {
    await widget.game.performVictoryUnlockAndDismiss();
    widget.onContinue?.call();
  }

  void _onClaimTap() {
    if (_isClaiming) return;
    setState(() {
      _isClaiming = true;
      _claimAmount = _displayedClaimAmount;
      _burstOrigin = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _wheelKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        const w = 210.0, h = 88.0;
        const pointerLen = 40.0;
        final tipX = w / 2 + pointerLen * sin(_pointerAngle);
        final tipY = h - 10 - pointerLen * cos(_pointerAngle);
        setState(() => _burstOrigin = box.localToGlobal(Offset(tipX, tipY)));
      }
      _claimEffectController.forward(from: 0);
    });
  }

  Future<void> _onExitTap() async => _runExitFlow();

  /// Thoát bằng back/exit: hiện warning, nếu xác nhận thì cộng _totalReward và đóng overlay. Chỉ khi bấm Claim thì cộng số claim, không warning.
  Future<void> _runExitFlow() async {
    final l10n = L10n;
    final confirmed = await ExitGameDialog.show(
      context,
      message: l10n.victoryExitLoseRewardWarning,
      exitRewardAmount: _totalReward,
    );
    if (!mounted || confirmed != true) return;
    await CoinService.instance.coinPlus(_totalReward);
    await _unlockAndDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    const rewardStyle = TextStyle(
      color: AppColors.gameOverOrange,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      shadows: AppColors.textOutlineWhite,
    );
    const statsRowWidth = 260.0;

    final content = Column(
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
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 100,
                    maxWidth: statsRowWidth,
                    minWidth: statsRowWidth,
                  ),
                  child: AnimatedBuilder(
                    animation: _statsController,
                    builder: (context, _) {
                      final p = _statsController.value;
                      const step = 1 / 3;
                      final line1Visible = p > 0;
                      final line2Visible = p >= step;
                      final line3Visible = p >= step * 2;
                      final d1 = _displayedForPhase(p, 0);
                      final d2 = _displayedForPhase(p, 1);
                      final d3 = _displayedForPhase(p, 2);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 32,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🎯', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('${l10n.victoryRewardLevelLabel}:', style: rewardStyle),
                                  ],
                                ),
                                Text(line1Visible ? '$d1 ${AppConstants.coinIcon}' : ' ', style: rewardStyle),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🕐', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('${l10n.victoryRewardTimeLabel}:', style: rewardStyle),
                                  ],
                                ),
                                Text(line2Visible ? '$d2 ${AppConstants.coinIcon}' : ' ', style: rewardStyle),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(AppConstants.coinIcon, style: rewardStyle),
                                    const SizedBox(width: 6),
                                    Text('${l10n.victoryRewardCoinsLabel}:', style: rewardStyle),
                                  ],
                                ),
                                Text(line3Visible ? '$d3 ${AppConstants.coinIcon}' : ' ', style: rewardStyle),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                key: _wheelKey,
                width: 210,
                height: 88,
                child: LuckyWheel(
                  size: const Size(210, 88),
                  rotationSpeed: _victoryWheelSpeed,
                  onPointerAngle: (angle) => setState(() => _pointerAngle = angle),
                  pausePointer: _isClaiming,
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GreenButton(
                    text: l10n.victoryClaimReward(_displayedClaimAmount)
                        .replaceAll(' xu', ' ${AppConstants.coinIcon}')
                        .replaceAll(' coins', ' ${AppConstants.coinIcon}'),
                    onPressed: _onClaimTap,
                    height: 64,
                    width: 200,
                  ),
                  Positioned(
                    top: -_adBadgeSize / 2 + _adBadgeOverlap,
                    right: -_adBadgeSize / 2 + _adBadgeOverlap,
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
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _onExitTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${l10n.victoryExit}  $_totalReward ${AppConstants.coinIcon}',
                    style: const TextStyle(
                      color: AppColors.gameOverOrange,
                      fontSize: 18,
                      shadows: AppColors.textOutlineWhite,
                    ),
                  ),
                ),
              ),
            ],
          );

    return Material(
      color: const Color(0xCC000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(child: Center(child: content)),
          if (_isClaiming)
            AnimatedBuilder(
              animation: _claimEffectController,
              builder: (_, __) => _VictoryClaimEffect(
                progress: _claimEffectController.value,
                multiplierLabel: _claimMultiplierLabel,
                burstOrigin: _burstOrigin,
              ),
            ),
        ],
      ),
    );
  }
}

/// Hiệu ứng claim: chữ X nổ scale to mờ dần + sao toả ra từ đầu kim, rơi xuống.
class _VictoryClaimEffect extends StatelessWidget {
  const _VictoryClaimEffect({
    required this.progress,
    required this.multiplierLabel,
    this.burstOrigin,
  });

  final double progress;
  final String multiplierLabel;
  final Offset? burstOrigin;

  static const int _starCount = 8;
  static const double _starFallDistance = 140;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = burstOrigin ?? Offset(size.width / 2, size.height / 2 - 20);

    final textScale = 0.3 + progress * 1.2;
    final textOpacity = progress < 0.5 ? 1.0 : (1 - (progress - 0.5) * 2).clamp(0.0, 1.0);

    return IgnorePointer(
      child: CustomPaint(
        size: size,
        painter: _ClaimEffectPainter(
          burstOrigin: center,
          progress: progress,
          starCount: _starCount,
          fallDistance: _starFallDistance,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Opacity(
              opacity: textOpacity,
              child: Transform.scale(
                scale: textScale,
                child: Text(
                  multiplierLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700),
                    shadows: [
                      Shadow(color: Colors.orange, blurRadius: 12, offset: Offset(0, 0)),
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimEffectPainter extends CustomPainter {
  _ClaimEffectPainter({
    required this.burstOrigin,
    required this.progress,
    this.starCount = 8,
    this.fallDistance = 140,
  });

  final Offset burstOrigin;
  final double progress;
  final int starCount;
  final double fallDistance;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < starCount; i++) {
      final angle = (i / starCount) * 2 * pi;
      final burst = progress.clamp(0.0, 1.0);
      final dist = burst * 100;
      final dy = burst * fallDistance;
      final x = burstOrigin.dx + cos(angle) * dist;
      final y = burstOrigin.dy + sin(angle) * dist + dy;
      final opacity = (1 - burst * 0.8).clamp(0.0, 1.0);
      final starOpacity = (opacity * 255).round().clamp(0, 255);
      final paint = Paint()..color = Color.fromARGB(starOpacity, 255, 215, 0);
      canvas.drawCircle(Offset(x, y), 10, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClaimEffectPainter old) =>
      old.progress != progress || old.burstOrigin != burstOrigin;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamePauseObserver.dialogOpen.value = true;
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamePauseObserver.dialogOpen.value = false;
    });
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
class _GameOverNoReviveOverlayWidget extends StatefulWidget {
  const _GameOverNoReviveOverlayWidget({
    required this.game,
    this.onGameOverEnd,
  });

  final WormJourneyGame game;
  final VoidCallback? onGameOverEnd;

  @override
  State<_GameOverNoReviveOverlayWidget> createState() => _GameOverNoReviveOverlayWidgetState();
}

class _GameOverNoReviveOverlayWidgetState extends State<_GameOverNoReviveOverlayWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamePauseObserver.dialogOpen.value = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamePauseObserver.dialogOpen.value = false;
    });
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
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  game.overlays.remove('GameOver');
                  game.overlays.remove('GameOverNoRevive');
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
