import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/services/shared_prefs_service.dart';
import '../models/item_model.dart';
import '../widgets/game_joystick.dart';
import '../widgets/item_info_dialog.dart';
import 'worm_journey_game.dart';

/// Màn game: GameWidget full màn + overlay GameJoystick (điều khiển rắn).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WormJourneyGame _game;
  Map<String, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _game = WormJourneyGame();
    _loadQuantities();
  }

  Future<void> _loadQuantities() async {
    final ids = commonItemList.map((e) => e.id);
    final map = await SharedPrefsService.getItemQuantities(ids);
    if (mounted) setState(() => _itemQuantities = map);
  }

  void _onUseItem(ItemModel item) {
    final q = _itemQuantities[item.id] ?? 0;
    if (q <= 0) return;
    setState(() => _itemQuantities[item.id] = q - 1);
    SharedPrefsService.setItemQuantity(item.id, q - 1);
    switch (item.effect) {
      case ItemEffect.evilMode:
        _game.triggerDevilModeByItem();
        break;
      case ItemEffect.none:
        break;
    }
  }

  void _onBuyItem(ItemModel item) {
    if (kDebugMode) {
      final q = _itemQuantities[item.id] ?? 0;
      final next = q + 10;
      setState(() => _itemQuantities[item.id] = next);
      SharedPrefsService.setItemQuantity(item.id, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GameWidget(game: _game),
              ),
              Container(
                width: double.infinity,
                color: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: commonItemList.map((item) => _ItemSlot(
                                item: item,
                                quantity: _itemQuantities[item.id] ?? 0,
                                game: _game,
                                onUse: () => _onUseItem(item),
                                onBuy: () => _onBuyItem(item),
                                onOpenDialog: () => _openItemDialog(item),
                              )).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GameJoystick(
                        game: _game,
                        size: 160,
                        baseRadius: 64,
                      )
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openItemDialog(ItemModel item) {
    _game.setPaused(true);
    ItemInfoDialog.show(
      context,
      item: item,
      onBuy: () => _onBuyItem(item),
      onReceive: () => _onUseItem(item),
    ).then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _game.setPaused(false);
      });
    });
  }
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    required this.item,
    required this.quantity,
    required this.game,
    required this.onUse,
    required this.onBuy,
    required this.onOpenDialog,
  });

  final ItemModel item;
  final int quantity;
  final WormJourneyGame game;
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
                  child: Text(item.icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'x$quantity',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
                  Icon(Icons.visibility_outlined, size: 10, color: Colors.grey.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'Xem',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade800),
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
