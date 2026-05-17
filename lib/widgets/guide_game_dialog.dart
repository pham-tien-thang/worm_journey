import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../inject/injection.dart';
import 'app_button.dart';

/// Dialog hướng dẫn: ảnh nền, title "Luật chơi" (l10n), content scroll từ JSON (guide_vi/guide_en), nút Đã hiểu.
class GuideGameDialog extends StatefulWidget {
  const GuideGameDialog({
    super.key,
    required this.guideText,
    required this.onUnderstood,
  });

  /// Nội dung hướng dẫn từ JSON (guide_vi hoặc guide_en), không bao gồm chữ "Luật chơi".
  final String guideText;
  final VoidCallback onUnderstood;

  static const String _imageAsset = 'assets/images/guide_game_dialog_50.png';
  static const double _padding = 28;

  @override
  State<GuideGameDialog> createState() => _GuideGameDialogState();
}

class _GuideGameDialogState extends State<GuideGameDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollVisibility());
    _scrollController.addListener(_updateScrollVisibility);
  }

  void _updateScrollVisibility() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final canScroll = pos.maxScrollExtent > 0 && pos.pixels < pos.maxScrollExtent - 2;
    if (canScroll != _canScrollDown) setState(() => _canScrollDown = canScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    const brown = AppColors.hudTextBrown;
    const double dialogWidth = 420;
    const double dialogHeight = 660;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 36),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(GuideGameDialog._imageAsset),
              fit: BoxFit.fill,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(GuideGameDialog._padding),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        l10n.gameRulesTitle,
                        style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle(fontSize: 22)).copyWith(
                              color: brown,
                              fontWeight: FontWeight.w800,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                        child: Text(
                          widget.guideText,
                          style: const TextStyle(
                            color: brown,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_canScrollDown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: brown,
                        size: 22,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: Text(l10n.understood),
                      onPressed: () => widget.onUnderstood(),
                      backgroundColor: AppColors.hudBorder,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ));
  }
}
