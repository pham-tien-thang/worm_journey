import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../inject/injection.dart';

/// Dialog cảnh báo thoát game: ảnh nền [waring_dialog.png], chữ "Trò chơi sẽ kết thúc ?", 2 nút Kết thúc (đỏ) và Huỷ (cam).
class ExitGameDialog extends StatelessWidget {
  const ExitGameDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  static const String _imageAsset = 'assets/images/waring_dialog.png';
  static const double _paddingHorizontal = 24;
  static const double _paddingBottom = 24;
  static const double _buttonSpacing = 12;
  static const double _contentPadding = 20;
  /// Dịch nội dung (chữ + nút) lên trên một chút.
  static const double _contentShiftUp = 14;

  /// [message] null = dùng l10n.exitGameWarningMessage (thoát game). Có message = dùng cho cảnh báo khác (vd. thoát victory mất thưởng).
  /// [exitRewardAmount] khi set (vd. thoát victory): nút xác nhận thành "Thoát xxx 🪙" để user biết vẫn nhận được xu.
  static Future<bool?> show(BuildContext context, {String? message, int? exitRewardAmount}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: _ExitGameDialogContent(
            message: message,
            exitRewardAmount: exitRewardAmount,
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ExitGameDialogContent(
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}

class _ExitGameDialogContent extends StatelessWidget {
  const _ExitGameDialogContent({
    this.message,
    this.exitRewardAmount,
    required this.onConfirm,
    required this.onCancel,
  });

  final String? message;
  final int? exitRewardAmount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    final displayMessage = message ?? l10n.exitGameWarningMessage;
    final confirmLabel = exitRewardAmount != null
        ? '${l10n.victoryExit}  $exitRewardAmount ${AppConstants.coinIcon}'
        : l10n.exitGameConfirm;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Image.asset(
          ExitGameDialog._imageAsset,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: ExitGameDialog._paddingHorizontal + ExitGameDialog._contentPadding,
            right: ExitGameDialog._paddingHorizontal + ExitGameDialog._contentPadding,
            bottom: ExitGameDialog._paddingBottom + ExitGameDialog._contentPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, -ExitGameDialog._contentShiftUp),
                child: Text(
                  displayMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      color: Colors.red,
                      onPressed: onConfirm,
                    ),
                  ),
                  const SizedBox(width: ExitGameDialog._buttonSpacing),
                  Expanded(
                    child: _DialogButton(
                      label: l10n.exitGameCancel,
                      color: Colors.orange,
                      onPressed: onCancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(999));
    return Material(
      color: color,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
