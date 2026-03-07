import 'package:flutter/cupertino.dart';

import '../gen_l10n/app_localizations.dart';

/// Global app context: navigator key và state dùng chung (force update, v.v.).
class AppContext {
  AppContext();

  final navigatorKey = GlobalKey<NavigatorState>();

  BuildContext get navigatorContext => navigatorKey.currentState!.context;

  final forceUpdateNeeded = ValueNotifier<bool>(false);

  /// L10n từ context của navigator. Trả về null nếu chưa có context (trước khi build).
  AppLocalizations? get l10n {
    final ctx = navigatorKey.currentContext ?? navigatorKey.currentState?.context;
    return ctx != null ? AppLocalizations.of(ctx) : null;
  }
}
