import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_colors.dart';
import '../../features/auth/login/presentation/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    
    Future.delayed(const Duration(milliseconds: 4000), () {
      _controller.forward().then((_) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginPage(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashScreenColor,
      body: FadeTransition(
        opacity: _animation,
        child: Center(
          child: Lottie.asset('assets/animations/splash_lottie.json',
            width: 500,
            height: 500,
          ),
        ),
      ),
    );
  }
}