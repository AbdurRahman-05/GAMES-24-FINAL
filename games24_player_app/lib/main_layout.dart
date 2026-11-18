import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        backgroundColor: const Color(0xFF080808),
        appBar: _buildAppBar(),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () {
                  showCreateTournamentDialog(context);
                },
                backgroundColor: const Color(0xFFD4FF00),
                elevation: 4,
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                label: const Text(
                  'Create Tournament',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF080808),
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
                  color: Color(0xFFD4FF00),
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
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFD4FF00)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          loc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFFA1A1AA)),
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
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: const Border(
          top: BorderSide(color: Color(0xFF262626), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAnimatedNavItem(
              0,
              Icons.home_outlined,
              Icons.home_rounded,
              'Home',
            ),
            _buildAnimatedNavItem(
              1,
              Icons.emoji_events_outlined,
              Icons.emoji_events_rounded,
              'Tournaments',
            ),
            _buildAnimatedNavItem(
              2,
              Icons.explore_outlined,
              Icons.explore_rounded,
              'Explore',
            ),
            _buildAnimatedNavItem(
              3,
              Icons.person_outline_rounded,
              Icons.person_rounded,
              'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4FF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
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
                isSelected ? solidIcon : outlineIcon,
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
      ),
    );
  }
}
