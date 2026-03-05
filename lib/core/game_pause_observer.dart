import 'package:flutter/material.dart';

/// Observer: khi dialog được push lên (route.opaque == false), gọi [onPauseChange](true).
/// Khi dialog pop, gọi [onPauseChange](false). [onPauseChange] do GameScreen set khi mount.
/// [dialogOpen] cho GamePlayScaffold disable thanh dưới (items + joystick) khi có dialog.
class GamePauseObserver extends NavigatorObserver {
  /// Callback do GameScreen đăng ký khi mount. Null khi không ở màn game.
  static void Function(bool paused)? onPauseChange;

  /// True khi có dialog đang mở. GamePlayScaffold dùng để IgnorePointer thanh dưới.
  static final ValueNotifier<bool> dialogOpen = ValueNotifier<bool>(false);

  static bool _isDialogRoute(Route<dynamic> route) =>
      route is ModalRoute && !route.opaque; // dialog thường có opaque = false

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isDialogRoute(route)) {
      if (onPauseChange != null) onPauseChange!(true);
      dialogOpen.value = true;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isDialogRoute(route)) {
      if (onPauseChange != null) onPauseChange!(false);
      dialogOpen.value = false;
    }
  }
}
