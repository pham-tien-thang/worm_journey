import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/debug_apply.dart';
import '../core/services/shared_prefs_service.dart';
import '../gen_l10n/app_localizations.dart';
import '../models/item_model.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_joystick.dart';
import '../widgets/item_info_dialog.dart';
import 'worm_journey_game.dart';

/// Scaffold chung cho màn chơi: nhận [game] đã tạo (theo level), hiển thị GameWidget + items + joystick.
/// Mỗi level có màn riêng tạo game rồi truyền vào đây, về sau dễ init map design từng level.
class GamePlayScaffold extends StatefulWidget {
  const GamePlayScaffold({super.key, required this.game});

  final WormJourneyGame game;

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
                      GameWidget(game: game),
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
                  color: Colors.grey.shade300,
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
                              padding: const EdgeInsets.only(top: 12),
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
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onOpenDialog,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 10,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    AppLocalizations.of(context).view,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
