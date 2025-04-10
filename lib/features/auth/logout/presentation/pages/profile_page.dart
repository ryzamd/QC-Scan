import 'package:architecture_scan_app/core/widgets/scafford_custom.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_bloc.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/dependencies.dart' as di;

class ProfilePage extends StatelessWidget {
  final UserEntity user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<LogoutBloc>(),
      child: CustomScaffold(
        title: 'PROFILE',
        showNavBar: true,
        currentIndex: 2,
        user: user,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF071952),
                Color(0xFF088395),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3a7bd5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  Text(
                    user.userId,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  const LogoutButton(
                    width: 200,
                    height: 50,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}