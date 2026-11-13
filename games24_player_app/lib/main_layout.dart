import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'tournaments_screen.dart';
import 'create_tournament_dialog.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'location_manager.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(
      onExploreTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
    ),
    const TournamentsScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
      // Add a global FAB specifically when on the Tournaments tab, matching design
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                showCreateTournamentDialog(context);
              },
              backgroundColor: const Color(0xFF154D36), // Botanical Emerald
              elevation: 2,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Create Tournament',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                ),
              ),
            )
          : null,
    ));
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: ValueListenableBuilder<String>(
        valueListenable: LocationManager().locationNotifier,
        builder: (context, loc, _) {
          return Row(
            children: [
              const Text(
                'GAMES24',
                style: TextStyle(
                  fontFamily: 'Delight',
                  color: Color(0xFF154D36),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => LocationManager.showLocationPicker(context),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF154D36)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          loc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF154D36),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF154D36)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 3;
            });
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png', // Fallback to logo if profile pic isn't available
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16, top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = constraints.maxWidth / 4;
            // The pill width is a bit smaller than the full item width to look nice
            final double pillWidth = 64.0;
            // Calculate the exact center position for the pill for the current index
            final double pillLeftPosition =
                (itemWidth * _currentIndex) + (itemWidth / 2) - (pillWidth / 2);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // The sliding animated pill indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  left: pillLeftPosition,
                  top: 0,
                  child: Container(
                    width: pillWidth,
                    height: 36, // Match the height of the icon container
                    decoration: BoxDecoration(
                      color: const Color(0xFF154D36).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // The actual navigation items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnimatedNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home,
                      'Home',
                      itemWidth,
                    ),
                    _buildAnimatedNavItem(
                      1,
                      Icons.emoji_events_outlined,
                      Icons.emoji_events,
                      'Tournaments',
                      itemWidth,
                    ),
                    _buildAnimatedNavItem(
                      2,
                      Icons.explore_outlined,
                      Icons.explore,
                      'Explore',
                      itemWidth,
                    ),
                    _buildAnimatedNavItem(
                      3,
                      Icons.person_outline,
                      Icons.person,
                      'Profile',
                      itemWidth,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
    double width,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isSelected ? solidIcon : outlineIcon,
                  key: ValueKey<bool>(isSelected),
                  size: 24,
                  color: isSelected
                      ? const Color(0xFF154D36)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF154D36)
                    : const Color(0xFF64748B),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
