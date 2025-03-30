import 'dart:convert';
import 'package:architecture_scan_app/core/errors/scan_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record_model.dart';

abstract class ScanLocalDataSource {
  /// Save a scan record locally
  ///
  /// Throws [ScanException] if saving fails
  Future<ScanRecordModel> saveScanRecord(ScanRecordModel record);
  
  /// Get all scan records for a specific user
  ///
  /// Throws [ScanException] if retrieval fails
  Future<List<ScanRecordModel>> getScanRecordsForUser(String userId);
  
  /// Clear all saved scan records for a user
  ///
  /// Throws [ScanException] if operation fails
  Future<bool> clearScanRecordsForUser(String userId);
}

class ScanLocalDataSourceImpl implements ScanLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  ScanLocalDataSourceImpl({required this.sharedPreferences});
  
  @override
  Future<ScanRecordModel> saveScanRecord(ScanRecordModel record) async {
    try {
      // Get existing records
      final records = await getScanRecordsForUser(record.userId);
      
      // Add new record
      records.add(record);
      
      // Save updated records
      final jsonList = records.map((record) => jsonEncode(record.toJson())).toList();
      await sharedPreferences.setStringList('scan_records_${record.userId}', jsonList);
      
      return record;
    } catch (e) {
      throw ScanException('Failed to save scan record: ${e.toString()}');
    }
  }
  
  @override
  Future<List<ScanRecordModel>> getScanRecordsForUser(String userId) async {
    try {
      final jsonList = sharedPreferences.getStringList('scan_records_$userId') ?? [];
      
      return jsonList
          .map((jsonString) => ScanRecordModel.fromJson(jsonDecode(jsonString)))
          .toList();
    } catch (e) {
      throw ScanException('Failed to get scan records: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> clearScanRecordsForUser(String userId) async {
    try {
      return await sharedPreferences.remove('scan_records_$userId');
    } catch (e) {
      throw ScanException('Failed to clear scan records: ${e.toString()}');
    }
  }
}