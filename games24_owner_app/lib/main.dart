import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      return true;
    }
    return false;
  };

  runApp(
    const ProviderScope(
      child: Games24OwnerApp(),
    ),
  );
}

class Games24OwnerApp extends ConsumerWidget {
  const Games24OwnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gamez24 Owner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
