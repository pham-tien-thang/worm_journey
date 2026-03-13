import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/services/coin_service.dart';

/// HUD hiển thị icon xu + số xu (format 1k, 1m, 1b). Dùng ở màn main, màn chọn level.
class CoinHud extends StatelessWidget {
  const CoinHud({
    super.key,
    this.style,
    this.iconSize,
  });

  final TextStyle? style;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        );
    final fs = iconSize ?? (effectiveStyle.fontSize ?? 18) * 1.1;

    return ListenableBuilder(
      listenable: CoinService.instance,
      builder: (context, _) {
        final coin = CoinService.instance.coin;
        final text = AppConstants.formatCoin(coin);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppConstants.coinIcon, style: TextStyle(fontSize: fs)),
            const SizedBox(width: 6),
            Text(text, style: effectiveStyle),
          ],
        );
      },
    );
  }
}
