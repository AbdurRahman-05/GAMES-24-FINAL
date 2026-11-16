import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class AdminMainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AdminMainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          onTabSelected(0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        extendBody: true,
        body: child,
        bottomNavigationBar: Container(
          color: const Color(0xFF080808),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF262626),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: currentIndex == 0 ? 12 : 10,
                      child: _buildNavItem(
                        index: 0,
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isSelected: currentIndex == 0,
                      ),
                    ),
                    Expanded(
                      flex: currentIndex == 1 ? 12 : 10,
                      child: _buildNavItem(
                        index: 1,
                        icon: Icons.edit_calendar_rounded,
                        label: 'Slots',
                        isSelected: currentIndex == 1,
                      ),
                    ),
                    Expanded(
                      flex: currentIndex == 2 ? 12 : 10,
                      child: _buildNavItem(
                        index: 2,
                        icon: Icons.emoji_events_rounded,
                        label: 'Tournaments',
                        isSelected: currentIndex == 2,
                      ),
                    ),
                    Expanded(
                      flex: currentIndex == 3 ? 12 : 10,
                      child: _buildNavItem(
                        index: 3,
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: currentIndex == 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTabSelected(index);
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 21 : 19,
              color: isSelected ? Colors.black : const Color(0xFF71717A),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFF71717A),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: isSelected ? 10.5 : 9.5,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
