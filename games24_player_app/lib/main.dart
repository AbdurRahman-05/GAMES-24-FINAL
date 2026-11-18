import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'core/theme/app_theme.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  // Guard against harmless Flutter Web Hot Restart engine view disposal race condition
  FlutterError.onError = (FlutterErrorDetails details) {
    final str = details.exceptionAsString();
    if (str.contains('EngineFlutterView') || str.contains('!isDisposed')) {
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final str = error.toString();
    if (str.contains('EngineFlutterView') || str.contains('!isDisposed')) {
      return true; // Marked as handled so hot restart doesn't freeze or crash the browser view
    }
    return false;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamez24',
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
