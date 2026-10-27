import 'package:flutter/material.dart';
import 'package:flutterwebapp/screen/webview_screen.dart';

// Website to be loaded inside the app
const websiteUrl = 'https://roozbehzarei.com/';

void main() {
// Ensure Flutter widgets are prepared
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: WebViewerScreen(url: websiteUrl),
    );
  }
}
