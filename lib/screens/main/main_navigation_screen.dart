import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../discover/discover_meals_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../planner/weekly_plan_screen.dart';
import '../timers/timers_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _onTap),
    const DiscoverMealsScreen(),
    const WeeklyPlanScreen(),
    const FavoritesScreen(),
    const TimersScreen(),
  ];

  void _onTap(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  final List<_NavItemData> _items = const [
    _NavItemData(
      label: 'Home',
      icon: Icons.home_rounded,
      outlinedIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Discover',
      icon: Icons.search_rounded,
      outlinedIcon: Icons.search_outlined,
    ),
    _NavItemData(
      label: 'Plan',
      icon: Icons.calendar_month_rounded,
      outlinedIcon: Icons.calendar_month_outlined,
    ),
    _NavItemData(
      label: 'Saved',
      icon: Icons.favorite_rounded,
      outlinedIcon: Icons.favorite_border_rounded,
    ),
    _NavItemData(
      label: 'Timers',
      icon: Icons.timer_rounded,
      outlinedIcon: Icons.timer_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: AppColors.borderGray.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: List.generate(
              _items.length,
                  (index) {
                final item = _items[index];
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: _BottomNavPillItem(
                    label: item.label,
                    icon: item.icon,
                    outlinedIcon: item.outlinedIcon,
                    isSelected: isSelected,
                    onTap: () => _onTap(index),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavPillItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData outlinedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavPillItem({
    required this.label,
    required this.icon,
    required this.outlinedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryGreen;
    final inactiveColor = AppColors.textGray;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : outlinedIcon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData outlinedIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.outlinedIcon,
  });
}