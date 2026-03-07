import 'package:get_it/get_it.dart';

import '../core/app_context.dart';
import '../gen_l10n/app_localizations.dart';

final GetIt _getIt = GetIt.instance;

/// Đăng ký toàn bộ dependency. Gọi trước [runApp].
void initInjection() {
  _getIt.registerLazySingleton<AppContext>(() => AppContext());
}

T get<T extends Object>() => _getIt.get<T>();

/// L10n từ navigator context. Chỉ dùng sau khi app đã build (trong màn hình, dialog).
AppLocalizations get L10n =>
    AppLocalizations.of(get<AppContext>().navigatorKey.currentContext!)!;
