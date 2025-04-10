import 'package:architecture_scan_app/core/network/dio_client.dart';
import 'package:architecture_scan_app/features/scan/data/datasources/scan_service_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LogoutDataSource {
  Future<bool> logoutDataSourceAsync();
}

class LogoutDataSourceImpl implements LogoutDataSource {
  final SharedPreferences sharedPreferences;
  final DioClient dioClient;

  LogoutDataSourceImpl({
    required this.sharedPreferences,
    required this.dioClient,
  });

  @override
  Future<bool> logoutDataSourceAsync() async {
    try {
      dioClient.clearAuthToken();
      
      ScanService.disposeScannerListener();
      
      await sharedPreferences.remove('user_token');
      
      final userId = sharedPreferences.getString('current_user_id');
      if (userId != null) {
        await sharedPreferences.remove('scan_records_$userId');
        await sharedPreferences.remove('current_user_id');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }
}