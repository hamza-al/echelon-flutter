import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'nutrition_screen.dart';
import 'coach_chat_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Start on middle (Workout) page
  final PageController _pageController = PageController(initialPage: 1);

  final List<Widget> _screens = [
    const ProgressScreen(),
    const HomeScreen(),
    const NutritionScreen(),
    CoachChatScreen(onNavigateBack: () {}), // Will be updated in build
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const PageScrollPhysics(),
            children: [
              _screens[0],
              _screens[1],
              _screens[2],
              CoachChatScreen(
                onNavigateBack: () => _onNavTapped(2), // Go to Nutrition tab
              ),
            ],
          ),
          
          // Floating navigation bar
          Positioned(
            left: 80,
            right: 80,
            bottom: 10,
            child: AnimatedOpacity(
              opacity: _currentIndex == 3 ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 50),
              child: IgnorePointer(
                ignoring: _currentIndex == 3,
                child: SafeArea(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 0,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: -5,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 60,
                          spreadRadius: 0,
                          offset: const Offset(0, 25),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Progress',
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.fitness_center,
                          label: 'Workout',
                          index: 1,
                          isMain: true,
                        ),
                        _buildNavItem(
                          icon: Icons.restaurant_outlined,
                          label: 'Nutrition',
                          index: 2,
                        ),
                        _buildNavItem(
                          icon: Icons.forum_rounded,
                          label: 'Coach',
                          index: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isMain = false,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }
}

