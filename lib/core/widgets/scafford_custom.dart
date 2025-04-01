// lib/common/widgets/custom_scaffold.dart
import 'package:architecture_scan_app/core/widgets/navbar_custom.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
    this.user
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.scaffoldBackground,
      appBar: customAppBar ?? _buildAppBar(context),
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: showNavBar
          ? CustomNavBar(currentIndex: currentIndex, user: user,)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D92F4)
        ),
      ),
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }
}