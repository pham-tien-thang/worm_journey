import 'package:flutter/material.dart';

import '../gen_l10n/app_localizations.dart';

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

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: _ExitGameDialogContent(
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
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  l10n.exitGameWarningMessage,
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
                      label: l10n.exitGameConfirm,
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
