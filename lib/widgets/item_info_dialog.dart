import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../gen_l10n/app_localizations.dart';
import '../models/item_model.dart';

/// Dialog thông tin item: title (icon + tên, nâu), mô tả, nút Mua, nút Nhận (xanh, nháy scale).
class ItemInfoDialog extends StatefulWidget {
  const ItemInfoDialog({
    super.key,
    required this.item,
    this.onBuy,
    this.onReceive,
  });

  final ItemModel item;
  final VoidCallback? onBuy;
  final VoidCallback? onReceive;

  static Future<void> show(
    BuildContext context, {
    required ItemModel item,
    VoidCallback? onBuy,
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
  late final Random _random = Random();
  int _getAmount = 0;
  Timer? _timer;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  static const Color _titleBrown = Color(0xFF5D4037);
  static const Color _receiveGreen = Color(0xFF4CAF50);

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    child: FilledButton(
                      onPressed: widget.onBuy != null
                          ? () {
                              widget.onBuy!();
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: Text(l10n.buyCoins(item.price)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Stack(
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
                          child: FilledButton(
                            onPressed: widget.onReceive != null
                                ? () {
                                    widget.onReceive!();
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _receiveGreen,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.amber, width: 2),
                            ),
                            child: Text(l10n.getCoins(_getAmount)),
                          ),
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
