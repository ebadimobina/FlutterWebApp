import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Smoke test - verify test runner and domain parsing', () {
    const testUrl = 'https://flutter.dev';
    final uri = Uri.parse(testUrl);
    expect(uri.host, equals('flutter.dev'));
  });
}
