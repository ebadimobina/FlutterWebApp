import 'package:get/get.dart';
import '../config/app_config.dart';
import '../controller/webview_controller.dart';

class WebViewerBinding extends Bindings {
  final String? url;

  WebViewerBinding({this.url});

  @override
  void dependencies() {
    Get.lazyPut<WebViewerController>(
      () => WebViewerController(url ?? AppConfig.initialUrl),
    );
  }
}
