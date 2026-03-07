import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/debug_apply.dart';
import '../core/app_colors.dart';
import '../game/entities/entity_models.dart';
import '../game/game.dart';
import '../inject/injection.dart';
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
      color: AppColors.hudTextBrown,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.hudBackground,
        border: const Border(
          top: BorderSide(color: AppColors.hudBorder, width: 4),
          bottom: BorderSide(color: AppColors.hudBorder, width: 1),
        ),
        // gradient: LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [
        //     Colors.black54,
        //     Colors.black26,
        //     Colors.transparent,
        //   ],
        //
        // ),
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
      if (e.effectTypeId == itemId) return e.icon;
    }
    return '❓';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in data.missions) ...[
          Builder(
            builder: (_) {
              final icon = EntityModels.icon(m.typeId);
              final type = EntityModels.projectType(m.typeId);
              final label = type?.displayName(l10n) ?? m.typeId;
              return Text(
                '$icon $label ${m.current}/${m.target}',
                style: textStyle,
              );
            },
          ),
          const SizedBox(height: 2),
        ],
        if (data.bossHpMax > 0)
          Row(
            children: [
              Text('HP boss ', style: textStyle),
              Text('👹', style: TextStyle(fontSize: textStyle?.fontSize ?? 16)),
              Text(' ×${data.bossHp}/${data.bossHpMax}', style: textStyle),
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
                style: textStyle?.copyWith(fontSize: 13),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _CenterSection extends StatefulWidget {
  const _CenterSection({required this.data, required this.textStyle});

  final GameHudData data;
  final TextStyle? textStyle;

  @override
  State<_CenterSection> createState() => _CenterSectionState();
}

class _CenterSectionState extends State<_CenterSection>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _colorController;
  late final Animation<Color?> _colorAnimation;
  bool _wasUrgent = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _colorAnimation = ColorTween(
      begin: AppColors.timeDisplayText,
      end: AppColors.timeUrgent,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showReady = widget.data.startDelayRemaining > 0;
    final seconds = widget.data.timeRemainingSeconds.ceil();
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    final timeStr = '$min:${sec.toString().padLeft(2, '0')}';
    final isUrgent = !showReady && seconds <= widget.data.timeUrgentThresholdSeconds;

    if (isUrgent && !_wasUrgent) {
      _wasUrgent = true;
      _scaleController.repeat(reverse: true);
      _colorController.repeat(reverse: true);
    } else if (!isUrgent && _wasUrgent) {
      _wasUrgent = false;
      _scaleController.stop();
      _scaleController.reset();
      _colorController.stop();
      _colorController.reset();
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.timeDisplayBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUrgent ? AppColors.timeUrgent : AppColors.hudBorder,
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scaleController, _colorController]),
            builder: (context, _) {
              return Transform.scale(
                scale: isUrgent ? _scaleAnimation.value : 1,
                child: Text(
                  '⏱',
                  style: TextStyle(
                    fontSize: 18,
                    color: isUrgent
                        ? _colorAnimation.value
                        : AppColors.timeDisplayText,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: Listenable.merge([_scaleController, _colorController]),
            builder: (context, child) {
              return Transform.scale(
                scale: isUrgent ? _scaleAnimation.value : 1,
                child: Text(
                  showReady ? 'Sẵn sàng' : timeStr,
                  style: (widget.textStyle ?? const TextStyle()).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isUrgent
                        ? _colorAnimation.value
                        : AppColors.timeDisplayText,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    return content;
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🪙', style: TextStyle(fontSize: textStyle?.fontSize ?? 16)),
            const SizedBox(width: 4),
            Text('${data.diamonds}', style: textStyle),
            if (kDebugMode) ...[
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DebugApplyToggle(textStyle: textStyle),
                  const SizedBox(height: 4),
                  _ShowCoordsToggle(textStyle: textStyle),
                ],
              ),
            ],
          ],
        ),
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
        final isOn = enabled;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => isDebugApplyEnabled = !isDebugApplyEnabled,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isOn
                    ? Colors.greenAccent.withOpacity(0.95)
                    : Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOn ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                isOn ? 'Debug ON' : 'Debug OFF',
                style: (textStyle ?? const TextStyle()).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOn ? Colors.black87 : Colors.orangeAccent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Nút ẩn/hiện tọa độ ô (Hide/Show coords). Chỉ hiện khi [kDebugMode]; đặt dưới nút Debug.
class _ShowCoordsToggle extends StatelessWidget {
  const _ShowCoordsToggle({this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showGridCoordinatesNotifier,
      builder: (context, showCoords, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showGridCoordinates = !showGridCoordinates,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: showCoords
                    ? Colors.blueAccent.withOpacity(0.3)
                    : Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: showCoords ? Colors.blue : Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                showCoords ? 'Coords ON' : 'Coords OFF',
                style: (textStyle ?? const TextStyle()).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: showCoords ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
