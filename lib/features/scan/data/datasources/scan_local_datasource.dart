import 'dart:convert';
import 'package:architecture_scan_app/core/errors/scan_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record_model.dart';

abstract class ScanLocalDataSource {
  Future<ScanRecordModel> saveScanRecordLocalDataSourceAsync(ScanRecordModel record);
  
  Future<List<ScanRecordModel>> getScanRecordsForUserLocalDataSourceAsync(String userId);
  
  Future<bool> clearScanRecordsForUserLocalDataSourceAsync(String userId);
}

class ScanLocalDataSourceImpl implements ScanLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  ScanLocalDataSourceImpl({required this.sharedPreferences});
  
  @override
  Future<ScanRecordModel> saveScanRecordLocalDataSourceAsync(ScanRecordModel record) async {
    try {

      final records = await getScanRecordsForUserLocalDataSourceAsync(record.userId);
      
      records.add(record);
      
      final jsonList = records.map((record) => jsonEncode(record.toJson())).toList();
      await sharedPreferences.setStringList('scan_records_${record.userId}', jsonList);
      
      return record;
    } catch (e) {
      throw ScanException('Failed to save scan record: ${e.toString()}');
    }
  }
  
  @override
  Future<List<ScanRecordModel>> getScanRecordsForUserLocalDataSourceAsync(String userId) async {
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
  Future<bool> clearScanRecordsForUserLocalDataSourceAsync(String userId) async {
    try {
      return await sharedPreferences.remove('scan_records_$userId');
    } catch (e) {
      throw ScanException('Failed to clear scan records: ${e.toString()}');
    }
  }
}