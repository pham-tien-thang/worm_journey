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

// --- Ẩn/hiện tọa độ ô (chỉ khi [shouldApplyDebug]; nút toggle ở HUD). Mặc định ẩn. ---
bool _showGridCoordinates = false;

bool get showGridCoordinates => _showGridCoordinates;

set showGridCoordinates(bool value) {
  if (_showGridCoordinates == value) return;
  _showGridCoordinates = value;
  _gridCoordNotifier ??= ValueNotifier<bool>(_showGridCoordinates);
  _gridCoordNotifier!.value = value;
}

ValueNotifier<bool>? _gridCoordNotifier;

ValueNotifier<bool> get showGridCoordinatesNotifier {
  _gridCoordNotifier ??= ValueNotifier<bool>(_showGridCoordinates);
  return _gridCoordNotifier!;
}

/// Có vẽ tọa độ ô (A1, B1...) hay không. False khi tắt debug hoặc user bấm "Hide coordinates".
bool get shouldShowGridCoordinates => shouldApplyDebug && _showGridCoordinates;
