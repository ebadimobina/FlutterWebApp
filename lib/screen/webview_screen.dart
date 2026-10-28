import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';
import '../controller/webview_controller.dart';

class WebViewerScreen extends StatelessWidget {
  final String url;
  late final WebViewerController controller;

  WebViewerScreen({super.key, String? url})
      : url = url ?? AppConfig.initialUrl {
    // If controller is already registered via binding, find it; otherwise put it
    if (Get.isRegistered<WebViewerController>()) {
      controller = Get.find<WebViewerController>();
    } else {
      controller = Get.put(WebViewerController(this.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await controller.canGoBack();
        if (canGoBack) {
          await controller.goBack();
        } else {
          final shouldExit = controller.handleExitPress();
          if (shouldExit && context.mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: _buildTopAppBar(context),
        body: SafeArea(
          top: !AppConfig.enableQuickActionsBar,
          child: Obx(() {
            if (!controller.hasInternetConnection.value) {
              return _buildOfflineView(context);
            }

            return Stack(
              children: [
                WebViewWidget(controller: controller.webViewController),
                if (controller.isLoading.value &&
                    controller.loadingPercentage.value > 0 &&
                    controller.loadingPercentage.value < 100)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: controller.loadingPercentage.value / 100.0,
                      backgroundColor: Colors.transparent,
                      minHeight: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildTopAppBar(BuildContext context) {
    if (!AppConfig.enableQuickActionsBar) return null;

    final theme = Theme.of(context);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() {
        return AppBar(
          elevation: 1,
          scrolledUnderElevation: 2,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed:
                controller.canGoBackHistory.value ? controller.goBack : null,
          ),
          title: Text(
            controller.currentTitle.value.isNotEmpty
                ? controller.currentTitle.value
                : AppConfig.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'Forward',
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              onPressed: controller.canGoForwardHistory.value
                  ? controller.goForward
                  : null,
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 22),
              onPressed: controller.pullToRefresh,
            ),
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: controller.shareCurrentUrl,
            ),
            PopupMenuButton<String>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_vert_rounded, size: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'copy':
                    controller.copyCurrentUrl();
                    break;
                  case 'browser':
                    controller.openInExternalBrowser();
                    break;
                  case 'home':
                    controller.webViewController.loadRequest(
                      Uri.parse(AppConfig.initialUrl),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'home',
                  child: Row(
                    children: [
                      Icon(Icons.home_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Home'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Copy link'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'browser',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_browser_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Open in browser'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOfflineView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No internet connection found. Please check your network and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: controller.retryConnection,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
