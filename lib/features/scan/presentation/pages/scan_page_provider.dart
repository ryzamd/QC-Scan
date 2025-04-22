import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../../../../core/di/dependencies.dart' as di;
import '../bloc/scan_bloc.dart';
import 'scan_page.dart';

class ScanPageProvider extends StatelessWidget {
  final UserEntity user;
  final bool isSpecialFeature;

  const ScanPageProvider({
    super.key,
    required this.user,
    required this.isSpecialFeature,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScanBloc>(
      create: (context) => di.sl<ScanBloc>(param1: user),
      child: ScanPage(
        user: user,
        isSpecialFeature: isSpecialFeature,
      ),
    );
  }
}