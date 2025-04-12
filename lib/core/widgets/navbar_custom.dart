import 'package:architecture_scan_app/core/constants/app_routes.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final UserEntity? user;
  final bool disableNavigation;

  const CustomNavBar({super.key, required this.currentIndex, this.user, this.disableNavigation = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF4158A6)),
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
      onTap: disableNavigation ? null : () {
        if (!isSelected) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
            (r) => false,
            arguments: user,
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
