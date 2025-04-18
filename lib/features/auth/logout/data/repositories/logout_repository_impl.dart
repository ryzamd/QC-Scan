import 'package:architecture_scan_app/core/di/dependencies.dart' as di;
import 'package:architecture_scan_app/core/repositories/auth_repository.dart';
import 'package:architecture_scan_app/features/auth/logout/data/datasources/logout_datasource.dart';
import 'package:architecture_scan_app/features/auth/logout/domain/repositories/logout_repository.dart';
import 'package:flutter/material.dart';

class LogoutRepositoryImpl implements LogoutRepository {
  final LogoutDataSource dataSource;

  LogoutRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<bool> logoutRepositoryAsync() async {
    try {
      return await di.sl<AuthRepository>().logoutAsync();

    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }
}