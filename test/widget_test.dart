import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Smoke test - verify test runner and domain parsing', () {
    const testUrl = 'https://mobinaebadi.com/';
    final uri = Uri.parse(testUrl);
    expect(uri.host, equals('mobinaebadi.com'));
  });
}
