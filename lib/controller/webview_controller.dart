import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewerController extends GetxController {
  final String url;
  late final WebViewController webViewController;

  final RxInt loadingPercentage = 0.obs;
  final RxBool hasInternetConnection = true.obs;

  WebViewerController(this.url);

  @override
  void onInit() {
    initializeWebView();
    super.onInit();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          final targetUri = Uri.tryParse(request.url);
          final baseUri = Uri.tryParse(url);

          if (targetUri != null && baseUri != null) {
            final targetHost =
                targetUri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
            final baseHost =
                baseUri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

            // Allow navigation if target host matches or is a subdomain of base host
            if (targetHost.isNotEmpty &&
                (targetHost == baseHost || targetHost.endsWith('.$baseHost'))) {
              return NavigationDecision.navigate;
            }
          }

          // Open external or special scheme links in external apps
          await launchExternalUrl(request.url);
          return NavigationDecision.prevent;
        },
        onPageStarted: (_) => hasInternetConnection.value = true,
        onProgress: (progress) => loadingPercentage.value = progress,
        onPageFinished: (_) {
          hasInternetConnection.value = true;
          loadingPercentage.value = 100;
        },
        // Detect network or DNS failure for the main frame
        onWebResourceError: (error) {
          final isMainFrame = error.isForMainFrame ?? true;
          if (isMainFrame &&
              (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.connect ||
                  error.errorType == WebResourceErrorType.timeout)) {
            hasInternetConnection.value = false;
            loadingPercentage.value = 0;
          }
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  // Retry reload if there was an error
  Future<void> retryConnection() async {
    hasInternetConnection.value = true;
    loadingPercentage.value = 0;
    await webViewController.reload();
  }

  // Launch external links via default browser / external app
  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    Get.snackbar('Error', 'Unable to handle this request');
  }

  // Navigation helpers for back functionality
  Future<bool> canGoBack() async => await webViewController.canGoBack();

  void goBack() => webViewController.goBack();
}
