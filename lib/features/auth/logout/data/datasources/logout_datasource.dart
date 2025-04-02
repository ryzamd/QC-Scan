import 'package:architecture_scan_app/core/network/dio_client.dart';
import 'package:architecture_scan_app/features/scan/data/datasources/scan_service_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LogoutDataSource {
  /// Perform logout operations: clear token, user data, and clean up resources
  ///
  /// Returns [bool] indicating success or failure
  Future<bool> logout();
}

class LogoutDataSourceImpl implements LogoutDataSource {
  final SharedPreferences sharedPreferences;
  final DioClient dioClient;
  //final ProcessingDataService processingDataService;

  LogoutDataSourceImpl({
    required this.sharedPreferences,
    required this.dioClient,
    // required this.processingDataService,
  });

  @override
  Future<bool> logout() async {
    try {
      // 1. Clear network authentication token
      dioClient.clearAuthToken();
      
      // 2. Clean up any hardware resources
      ScanService.disposeScannerListener();
      
      // 3. Clear processing data
     // processingDataService.clearItems();
      
      // 4. Clear user token from SharedPreferences
      await sharedPreferences.remove('user_token');
      
      // 5. Clear user-specific scan records
      // Find keys related to scan records and remove them
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