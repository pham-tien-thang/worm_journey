import 'package:flutter_test/flutter_test.dart';
import 'package:worm_journey/core/app_constants.dart';

void main() {
  test('formats compact coin values', () {
    expect(AppConstants.formatCoin(999), '999');
    expect(AppConstants.formatCoin(1000), '1k');
    expect(AppConstants.formatCoin(1500), '1.5k');
    expect(AppConstants.formatCoin(1000000), '1m');
  });
}
