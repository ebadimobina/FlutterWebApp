class AppConfig {
  static const String appName = 'Flutter Web App';
  static const String initialUrl = 'https://flutter.dev';
  static const bool enablePullToRefresh = true;
  static const bool enableDoubleTapExit = true;
  static const Duration doubleTapExitDuration = Duration(seconds: 2);
  static const bool enableQuickActionsBar = true;
  static const List<String> additionalAllowedHosts = <String>[];
  static bool isInternalUrl(Uri targetUri, Uri baseUri) {
    if (targetUri.scheme != 'http' && targetUri.scheme != 'https') {
      return false;
    }

    final targetHost =
        targetUri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final baseHost =
        baseUri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

    if (targetHost.isEmpty) return false;
    if (targetHost == baseHost || targetHost.endsWith('.$baseHost')) {
      return true;
    }
    for (final host in additionalAllowedHosts) {
      final cleanHost = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
      if (targetHost == cleanHost || targetHost.endsWith('.$cleanHost')) {
        return true;
      }
    }

    return false;
  }
}
