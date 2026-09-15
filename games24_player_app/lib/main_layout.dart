import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'tournaments_screen.dart';
import 'create_tournament_dialog.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
      // Add a global FAB specifically when on the Tournaments tab, matching design
      floatingActionButton: _currentIndex == 1 
          ? FloatingActionButton.extended(
              onPressed: () {
                showCreateTournamentDialog(context);
              },
              backgroundColor: const Color(0xFF166534), // Dark green
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                'Create Tournament',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'GAMES24',
        style: TextStyle(
          fontFamily: 'Delight',
          color: Color(0xFF166534), // Dark Green
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              color: Colors.black12,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
          onPressed: () {},
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
            color: Colors.black.withOpacity(0.04),
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
            final double pillLeftPosition = (itemWidth * _currentIndex) + (itemWidth / 2) - (pillWidth / 2);

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
                      color: const Color(0xFF0F6D38).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // The actual navigation items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnimatedNavItem(0, Icons.home_outlined, Icons.home, 'Home', itemWidth),
                    _buildAnimatedNavItem(1, Icons.emoji_events_outlined, Icons.emoji_events, 'Tournaments', itemWidth),
                    _buildAnimatedNavItem(2, Icons.explore_outlined, Icons.explore, 'Explore', itemWidth),
                    _buildAnimatedNavItem(3, Icons.person_outline, Icons.person, 'Profile', itemWidth),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, IconData outlineIcon, IconData solidIcon, String label, double width) {
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
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  isSelected ? solidIcon : outlineIcon,
                  key: ValueKey<bool>(isSelected),
                  size: 24,
                  color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFF6B7280),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
