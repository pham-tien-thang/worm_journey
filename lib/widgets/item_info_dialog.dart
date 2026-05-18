import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/services/coin_service.dart';
import '../core/services/shared_prefs_service.dart';
import '../inject/injection.dart';
import '../models/item_model.dart';
import 'app_button.dart';

/// Dialog thông tin item: title (icon + tên, nâu), mô tả, nút Mua, nút Nhận (xanh, nháy scale).
/// [onBuy] trả về Future<bool>: true = mua thành công (đóng dialog), false = không đủ vàng.
class ItemInfoDialog extends StatefulWidget {
  const ItemInfoDialog({
    super.key,
    required this.item,
    this.onBuy,
    this.onReceive,
  });

  final ItemModel item;
  /// Trả về true nếu mua thành công (đóng dialog), false nếu không đủ vàng.
  final Future<bool> Function()? onBuy;
  final VoidCallback? onReceive;

  static Future<void> show(
    BuildContext context, {
    required ItemModel item,
    Future<bool> Function()? onBuy,
    VoidCallback? onReceive,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ItemInfoDialog(
        item: item,
        onBuy: onBuy,
        onReceive: onReceive,
      ),
    );
  }

  @override
  State<ItemInfoDialog> createState() => _ItemInfoDialogState();
}

class _ItemInfoDialogState extends State<ItemInfoDialog>
    with SingleTickerProviderStateMixin {
  static const int _freeCoinCooldownSeconds = 5 * 60; // 5 phút

  late final Random _random = Random();
  int _getAmount = 0;
  Timer? _timer;
  Timer? _cooldownTimer;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  /// Timestamp (ms) lần cuối nhận free coin. Null = chưa từng.
  int? _freeCoinLastAtMs;
  /// Số giây còn chờ (< 0: đang load, 0: được nhận, > 0: countdown).
  int _freeCoinRemainingSeconds = -1;

  static const Color _titleBrown = Color(0xFF5D4037);
  static const Color _receiveGreen = Color(0xFF4CAF50);

  void _recalcFreeCoinRemaining() {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final lastAt = _freeCoinLastAtMs;
    if (lastAt == null) {
      _freeCoinRemainingSeconds = 0;
      return;
    }
    final elapsed = nowSec - (lastAt ~/ 1000);
    _freeCoinRemainingSeconds = (_freeCoinCooldownSeconds - elapsed).clamp(0, _freeCoinCooldownSeconds);
  }

  static String _formatCountdown(int seconds) {
    if (seconds < 0) return '...';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _getAmount = 50 + _random.nextInt(51);
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) setState(() => _getAmount = 50 + _random.nextInt(51));
    });
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    SharedPrefsService.getFreeRandomCoinLastAt().then((v) {
      if (!mounted) return;
      setState(() {
        _freeCoinLastAtMs = v;
        _recalcFreeCoinRemaining();
      });
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _recalcFreeCoinRemaining();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    final item = widget.item;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.type.name(l10n),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _titleBrown,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.type.description(l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: Text(l10n.buyCoins(item.price, AppConstants.coinIcon)),
                      onPressed: widget.onBuy != null
                          ? () async {
                              final ok = await widget.onBuy!();
                              if (ok && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                      isEnabled: widget.onBuy != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Builder(
                          builder: (context) {
                            final canReceive = _freeCoinRemainingSeconds == 0;
                            final label = canReceive
                                ? Text(l10n.getCoins(_getAmount, AppConstants.coinIcon))
                                : Text(l10n.waitCountdown(_formatCountdown(_freeCoinRemainingSeconds)));
                            final button = AppButton(
                              label: label,
                              onPressed: canReceive
                                  ? () async {
                                      await SharedPrefsService.setFreeRandomCoinLastAt(
                                        DateTime.now().millisecondsSinceEpoch,
                                      );
                                      await CoinService.instance.coinPlus(_getAmount);
                                      widget.onReceive?.call();
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    }
                                  : null,
                              backgroundColor: _receiveGreen,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.amber, width: 2),
                              isEnabled: canReceive,
                            );
                            if (canReceive) {
                              return AnimatedBuilder(
                                animation: _scaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: child,
                                  );
                                },
                                child: button,
                              );
                            }
                            return button;
                          },
                        ),
                        Positioned(
                          top: -6,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade700, width: 1),
                            ),
                            child: const Text('🎬', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
