// lib/features/scan/presentation/pages/scan_page_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../../../../core/di/dependencies.dart' as di;
import '../bloc/scan_bloc.dart';
import 'scan_page.dart';

/// Provider that creates and provides the ScanBloc to the ScanPage
class ScanPageProvider extends StatelessWidget {
  final UserEntity user;

  const ScanPageProvider({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScanBloc>(
      create: (context) => di.sl<ScanBloc>(param1: user),
      child: ScanPage(user: user),
    );
  }
}
