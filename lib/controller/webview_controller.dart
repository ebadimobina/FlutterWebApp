import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';

class WebViewerController extends GetxController {
  final String url;
  late final WebViewController webViewController;

  final RxInt loadingPercentage = 0.obs;
  final RxBool hasInternetConnection = true.obs;
  final RxBool isLoading = false.obs;
  final RxString currentUrl = ''.obs;
  final RxString currentTitle = ''.obs;
  final RxBool canGoBackHistory = false.obs;
  final RxBool canGoForwardHistory = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DateTime? _lastBackPressTime;

  WebViewerController(this.url);

  @override
  void onInit() {
    currentUrl.value = url;
    initializeWebView();
    _initConnectivityListener();
    super.onInit();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else if (WebViewPlatform.instance is AndroidWebViewController) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          Get.snackbar(
            AppConfig.appName,
            message.message,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          final targetUri = Uri.tryParse(request.url);
          final baseUri = Uri.tryParse(url);

          if (targetUri == null || baseUri == null) {
            return NavigationDecision.prevent;
          }

          // Handle internal navigation
          if (AppConfig.isInternalUrl(targetUri, baseUri)) {
            return NavigationDecision.navigate;
          }

          // Open external links or other schemes (tel, mailto, sms, etc.) in external apps
          await launchExternalUrl(request.url);
          return NavigationDecision.prevent;
        },
        onPageStarted: (startedUrl) {
          isLoading.value = true;
          hasInternetConnection.value = true;
          currentUrl.value = startedUrl;
        },
        onProgress: (progress) {
          loadingPercentage.value = progress;
        },
        onPageFinished: (finishedUrl) async {
          isLoading.value = false;
          hasInternetConnection.value = true;
          loadingPercentage.value = 100;
          currentUrl.value = finishedUrl;

          // Update page title
          final title = await controller.getTitle();
          if (title != null && title.isNotEmpty) {
            currentTitle.value = title;
          }

          // Update history flags
          await _updateHistoryState();
        },
        onWebResourceError: (error) {
          final isMainFrame = error.isForMainFrame ?? true;
          if (isMainFrame &&
              (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.connect ||
                  error.errorType == WebResourceErrorType.timeout)) {
            hasInternetConnection.value = false;
            loadingPercentage.value = 0;
            isLoading.value = false;
          }
        },
      ));

    // Platform-specific enhancements
    if (controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    } else if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(url));
    webViewController = controller;
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && !hasInternetConnection.value) {
        // Automatically restore connection and reload
        retryConnection();
      }
    });
  }

  Future<void> _updateHistoryState() async {
    canGoBackHistory.value = await webViewController.canGoBack();
    canGoForwardHistory.value = await webViewController.canGoForward();
  }

  Future<void> retryConnection() async {
    hasInternetConnection.value = true;
    loadingPercentage.value = 0;
    isLoading.value = true;
    await webViewController.reload();
  }

  Future<void> pullToRefresh() async {
    hasInternetConnection.value = true;
    await webViewController.reload();
  }

  Future<void> launchExternalUrl(String targetUrl) async {
    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    Get.snackbar(
      'Error',
      'Unable to open this link',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Navigation helpers
  Future<bool> canGoBack() async => await webViewController.canGoBack();

  Future<void> goBack() async {
    if (await canGoBack()) {
      await webViewController.goBack();
      await _updateHistoryState();
    }
  }

  Future<void> goForward() async {
    if (await webViewController.canGoForward()) {
      await webViewController.goForward();
      await _updateHistoryState();
    }
  }

  // Share and Action helpers
  Future<void> shareCurrentUrl() async {
    final urlToShare = currentUrl.value.isNotEmpty ? currentUrl.value : url;
    final title =
        currentTitle.value.isNotEmpty ? currentTitle.value : AppConfig.appName;
    await SharePlus.instance.share(
      ShareParams(
        text: urlToShare,
        subject: title,
      ),
    );
  }

  Future<void> copyCurrentUrl() async {
    final urlToCopy = currentUrl.value.isNotEmpty ? currentUrl.value : url;
    await Clipboard.setData(ClipboardData(text: urlToCopy));
    Get.snackbar(
      'Copied',
      'Page URL copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> openInExternalBrowser() async {
    final urlToOpen = currentUrl.value.isNotEmpty ? currentUrl.value : url;
    await launchExternalUrl(urlToOpen);
  }

  /// Handles back navigation with double-tap to exit logic
  /// Returns `true` if the app should exit, `false` otherwise.
  bool handleExitPress() {
    if (!AppConfig.enableDoubleTapExit) return true;

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > AppConfig.doubleTapExitDuration) {
      _lastBackPressTime = now;
      Get.rawSnackbar(
        message: 'Press back again to exit',
        duration: AppConfig.doubleTapExitDuration,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        borderRadius: 12,
      );
      return false;
    }
    return true;
  }
}
