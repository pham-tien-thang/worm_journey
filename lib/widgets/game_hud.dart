import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/debug_apply.dart';
import '../game/worm_journey_game.dart';
import '../models/item_model.dart';

/// Thanh HUD phía trên màn chơi: thời gian giữa, kim cương bên phải, nhiệm vụ & hiệu ứng bên trái.
/// Dữ liệu cập nhật trong lúc chơi; sau sẽ load từ JSON config.
class GameHud extends StatefulWidget {
  const GameHud({
    super.key,
    required this.game,
    this.pollInterval = const Duration(milliseconds: 200),
  });

  final WormJourneyGame game;
  final Duration pollInterval;

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  Timer? _timer;
  GameHudData _data = const GameHudData(
    timeRemainingSeconds: 0,
    diamonds: 0,
    missions: [],
    bossHp: 0,
    bossHpMax: 0,
    itemBuffs: [],
    startDelayRemaining: 0,
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.pollInterval, (_) {
      if (!mounted) return;
      setState(() => _data = widget.game.hudData);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _data = widget.game.hudData;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.black26,
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: _LeftSection(data: _data, textStyle: textStyle),
            ),
            _CenterSection(data: _data, textStyle: textStyle),
            Expanded(
              child: _RightSection(data: _data, textStyle: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftSection extends StatelessWidget {
  const _LeftSection({required this.data, required this.textStyle});

  final GameHudData data;
  final TextStyle? textStyle;

  static String _itemIcon(String itemId) {
    for (final e in commonItemList) {
      if (e.id == itemId) return e.icon;
    }
    return '❓';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in data.missions) ...[
          Text(
            m.icon != null ? '${m.icon} ${m.label} ${m.current}/${m.target}' : '${m.label} ${m.current}/${m.target}',
            style: textStyle,
          ),
          const SizedBox(height: 2),
        ],
        Row(
          children: [
            Text('HP boss ', style: textStyle),
            Text('👹', style: TextStyle(fontSize: textStyle?.fontSize ?? 12)),
            Text(' ×${data.bossHp}', style: textStyle),
          ],
        ),
        if (data.itemBuffs.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: data.itemBuffs.map((b) {
              final sec = b.remainingSeconds.ceil();
              final icon = _itemIcon(b.itemId);
              return Text(
                '$icon ${sec}s',
                style: textStyle?.copyWith(fontSize: 10),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _CenterSection extends StatelessWidget {
  const _CenterSection({required this.data, required this.textStyle});

  final GameHudData data;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final showReady = data.startDelayRemaining > 0;
    final seconds = data.timeRemainingSeconds.ceil();
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    final timeStr = '$min:${sec.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        showReady ? 'Sẵn sàng' : timeStr,
        style: (textStyle ?? const TextStyle()).copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RightSection extends StatelessWidget {
  const _RightSection({required this.data, required this.textStyle});

  final GameHudData data;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💎', style: TextStyle(fontSize: textStyle?.fontSize ?? 14)),
          const SizedBox(width: 4),
          Text('${data.diamonds}', style: textStyle),
          if (kDebugMode) ...[
            const SizedBox(width: 12),
            _DebugApplyToggle(textStyle: textStyle),
          ],
        ],
      ),
    );
  }
}

/// Nút bật/tắt "áp dụng debug" (common). Chỉ hiện khi [kDebugMode]; không tự áp dụng với chính nó.
class _DebugApplyToggle extends StatelessWidget {
  const _DebugApplyToggle({this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: debugApplyNotifier,
      builder: (context, enabled, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => isDebugApplyEnabled = !isDebugApplyEnabled,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                enabled ? 'Debug ON' : 'Debug OFF',
                style: (textStyle ?? const TextStyle()).copyWith(
                  fontSize: 10,
                  color: enabled ? Colors.lightGreen : Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
