import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Games24',
      theme: ThemeData(
        fontFamily: 'Delight',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
      ),
      home: const SplashScreen(),
    );
  }
}
