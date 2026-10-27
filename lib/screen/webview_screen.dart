import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controller/webview_controller.dart';

class WebViewerScreen extends StatelessWidget {
  final String url;
  final WebViewerController controller;

  WebViewerScreen({super.key, required this.url})
      : controller = Get.put(WebViewerController(url));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await controller.canGoBack();
        if (canGoBack) {
          controller.goBack();
        } else {
          if (context.mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: SafeArea(
        child: Obx(() {
          if (!controller.hasInternetConnection.value) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 90,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Could not load the page',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your internet connection and try again.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: controller.retryConnection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            body: Stack(
              children: [
                WebViewWidget(controller: controller.webViewController),
                if (controller.loadingPercentage.value > 0 &&
                    controller.loadingPercentage.value < 100)
                  LinearProgressIndicator(
                    value: controller.loadingPercentage.value / 100.0,
                    color: Theme.of(context).primaryColor,
                    backgroundColor: Colors.transparent,
                    minHeight: 3,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
