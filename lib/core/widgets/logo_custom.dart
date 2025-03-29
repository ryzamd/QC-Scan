// lib/core/widgets/logo_widget.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

Widget buildLogoWidget() {
  return Column(
    children: [
      Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardBackgroundDark.withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 13.0),
          child: Image.asset(
            'assets/images/zucca-logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'PRO WELL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins'
        )
      ),
    ],
  );
}