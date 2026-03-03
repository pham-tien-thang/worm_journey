import 'package:flutter/foundation.dart';

/// Cờ "áp dụng debug" dùng chung toàn app.
/// Chỉ khi [kDebugMode] **và** [isDebugApplyEnabled] == true thì các tính năng debug mới hiệu lực.
/// Nút bật/tắt debug (trong HUD) chỉ hiện khi [kDebugMode]; nút không tự áp dụng với chính nó.
bool _debugApplyEnabled = true;

bool get isDebugApplyEnabled => _debugApplyEnabled;

set isDebugApplyEnabled(bool value) {
  if (_debugApplyEnabled == value) return;
  _debugApplyEnabled = value;
  _notifier ??= ValueNotifier(_debugApplyEnabled);
  _notifier!.value = value;
}

ValueNotifier<bool>? _notifier;

ValueNotifier<bool> get debugApplyNotifier {
  _notifier ??= ValueNotifier(_debugApplyEnabled);
  return _notifier!;
}

/// Trả về true chỉ khi đang build debug **và** user bật "apply debug". Dùng thay cho [kDebugMode] ở mọi chỗ cần áp dụng tính năng debug (overlay tọa độ, tap pause, v.v.).
bool get shouldApplyDebug => kDebugMode && _debugApplyEnabled;
