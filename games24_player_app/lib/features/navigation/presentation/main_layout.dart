import 'package:flutter/material.dart';
import 'widgets/floating_bottom_nav.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
    );
  }
}
