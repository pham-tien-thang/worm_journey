import 'package:flutter/material.dart';

import '../models/item_model.dart';

/// Dialog thông tin item: tên + X, mô tả, nút Mua, nút Nhận (có icon quảng cáo).
class ItemInfoDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onBuy != null
                          ? () {
                              onBuy!();
                              Navigator.of(context).pop();
                            }
                          : null,
                      icon: const Icon(Icons.store, size: 20),
                      label: Text('Mua ${item.price}💎'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FilledButton.icon(
                          onPressed: onReceive != null
                              ? () {
                                  onReceive!();
                                  Navigator.of(context).pop();
                                }
                              : null,
                          icon: Text(item.icon, style: const TextStyle(fontSize: 20)),
                          label: const Text('Nhận'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Material(
                            elevation: 2,
                            shadowColor: Colors.black38,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade400,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade700, width: 1),
                              ),
                              child: const Icon(Icons.campaign, size: 16, color: Colors.black87),
                            ),
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
