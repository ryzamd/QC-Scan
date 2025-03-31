// lib/common/widgets/custom_navbar.dart
import 'package:architecture_scan_app/core/constants/app_routes.dart';
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF0D92F4)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                index: 0,
                route: AppRoutes.processing,
              ),
              _buildNavItem(
                context,
                icon: Icons.work_rounded,
                selectedIcon: Icons.work_rounded,
                index: 1,
                route: AppRoutes.scan,
                badge: true,
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                index: 2,
                route: AppRoutes.profile,
                badge: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required int index,
    required String route,
    bool badge = false,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
            (r) => false, // Remove all previous routes
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color:
                      isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
