import 'package:architecture_scan_app/core/widgets/scafford_custom.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_bloc.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/enum.dart';
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
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: user.role == UserRole.scanQc1 ? Color(0xFF399918) : Color(0xFFFF7F3E),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFECE9E6)),
                        child: ClipOval(
                          child: SizedBox.fromSize(
                            size: const Size.fromRadius(48),
                            child: user.role == UserRole.scanQc1 ? Image.asset('assets/avatar/Frog.png')
                                                                        : Image.asset('assets/avatar/Cat.png', cacheHeight: 91),
                          )
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

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == UserRole.scanQc1 ? '品管質檢' : '品管正式倉',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
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