import 'package:architecture_scan_app/core/widgets/navbar_custom.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/navigation_service.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showNavBar;
  final int currentIndex;
  final bool showBackButton;
  final Color? backgroundColor;
  final PreferredSizeWidget? customAppBar;
  final UserEntity? user;
  final bool showHomeIcon;
  final Function(int)? customNavBarCallback;

  const CustomScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showNavBar = true,
    this.currentIndex = 0,
    this.showBackButton = false,
    this.backgroundColor,
    this.customAppBar,
    this.user,
    required this.showHomeIcon,
    this.customNavBarCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.scaffoldBackground,
      appBar: customAppBar ?? _buildAppBar(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: body,
      ),
     bottomNavigationBar: showNavBar ? CustomNavBar(
                            currentIndex: currentIndex,
                            user: user,
                            showHomeIcon: showHomeIcon,
                            customCallback: customNavBarCallback,
                          ) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {

    final navigationService = NavigationService();
    final shouldShowBack = navigationService.shouldShowBackButton(context);
    
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF4158A6)
        ),
      ),
      elevation: 0,
      centerTitle: true,
      titleSpacing: 4,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.scaffoldBackground,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: shouldShowBack && showHomeIcon
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.scaffoldBackground),
                onPressed: () => navigationService.handleBackButton(context),
              )
            : null,
      actions: actions,
    );
  }
}