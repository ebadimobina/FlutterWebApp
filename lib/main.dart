import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'binding/webview_binding.dart';
import 'config/app_config.dart';
import 'screen/webview_screen.dart';

void main() {
  // Ensure Flutter widgets are prepared
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF02569B),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF02569B),
          brightness: Brightness.dark,
        ),
      ),
      initialBinding: WebViewerBinding(),
      home: WebViewerScreen(),
    );
  }
}
