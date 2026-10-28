import 'package:flutter_test/flutter_test.dart';
import 'package:flutterwebapp/config/app_config.dart';

void main() {
  group('AppConfig & URL Routing Tests', () {
    final baseUri = Uri.parse('https://flutter.dev');

    test('should allow same domain and paths', () {
      final targetUri = Uri.parse('https://flutter.dev/community');
      expect(AppConfig.isInternalUrl(targetUri, baseUri), isTrue);
    });

    test('should allow www version of same domain', () {
      final targetUri = Uri.parse('https://www.flutter.dev/docs');
      expect(AppConfig.isInternalUrl(targetUri, baseUri), isTrue);
    });

    test('should allow subdomains of base domain', () {
      final targetUri = Uri.parse(
          'https://api.flutter.dev/flutter/widgets/Widget-class.html');
      expect(AppConfig.isInternalUrl(targetUri, baseUri), isTrue);
    });

    test('should prevent external domains', () {
      final targetUri = Uri.parse('https://example.com');
      expect(AppConfig.isInternalUrl(targetUri, baseUri), isFalse);
    });

    test('should prevent non-http schemes like tel, mailto, sms', () {
      expect(AppConfig.isInternalUrl(Uri.parse('tel:123456789'), baseUri),
          isFalse);
      expect(
          AppConfig.isInternalUrl(
              Uri.parse('mailto:support@flutter.dev'), baseUri),
          isFalse);
      expect(AppConfig.isInternalUrl(Uri.parse('sms:123456789'), baseUri),
          isFalse);
    });

    test('verify app configuration defaults', () {
      expect(AppConfig.appName, isNotEmpty);
      expect(AppConfig.initialUrl, startsWith('https://'));
      expect(AppConfig.enableDoubleTapExit, isTrue);
      expect(AppConfig.enableQuickActionsBar, isTrue);
    });
  });
}
