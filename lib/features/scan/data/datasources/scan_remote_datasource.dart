import 'package:architecture_scan_app/core/errors/scan_exceptions.dart';
import 'package:dio/dio.dart';
import '../models/scan_record_model.dart';


abstract class ScanRemoteDataSource {
  /// Get material information based on a barcode
  ///
  /// Throws [MaterialNotFoundException] if material not found
  /// Throws [ScanException] if operation fails
  Future<Map<String, String>> getMaterialInfo(String barcode);
  
  /// Send scan records to processing
  ///
  /// Throws [ProcessingException] if processing fails
  Future<bool> sendToProcessing(List<ScanRecordModel> records);
}

class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  final Dio dio;
  
  ScanRemoteDataSourceImpl({required this.dio});
  
  @override
  Future<Map<String, String>> getMaterialInfo(String barcode) async {
    try {
      // Simulate API call to get material info
      // In production, you would call a real API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulated material info for testing
      if (barcode.isEmpty) {
        throw MaterialNotFoundException(barcode);
      }
      
      // Mock different material info based on barcode
      if (barcode.contains('MAT')) {
        return {
          'Material ID': barcode,
          'Material Name': 'Steel Plate ${barcode.substring(3)}',
          'Category': 'Raw Material',
          'Supplier': 'ProWell Industries',
          'Batch': 'B-${barcode.hashCode.toString().substring(0, 4)}',
          'Quantity': '10',
        };
      } else if (barcode.contains('PROD')) {
        return {
          'Material ID': barcode,
          'Material Name': 'Finished Product ${barcode.substring(4)}',
          'Category': 'Finished Good',
          'Production Date': DateTime.now().subtract(const Duration(days: 2)).toString().substring(0, 10),
          'Inspector': 'QC Team',
          'Quantity': '1',
        };
      } else {
        return {
          'Material ID': barcode,
          'Material Name': 'Generic Material',
          'Category': 'Miscellaneous',
          'Location': 'Warehouse',
          'Scan Time': DateTime.now().toString().substring(0, 19),
          'Quantity': '1',
        };
      }
    } on DioException catch (e) {
      throw ScanException('Network error: ${e.message}');
    } catch (e) {
      if (e is MaterialNotFoundException) {
        rethrow;
      }
      throw ScanException('Failed to get material info: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> sendToProcessing(List<ScanRecordModel> records) async {
    try {
      // Simulate API call to send records to processing
      // In production, you would call a real API
      await Future.delayed(const Duration(seconds: 1));
      
      // For testing purposes, always return true
      return true;
    } on DioException catch (e) {
      throw ProcessingException('Network error: ${e.message}');
    } catch (e) {
      throw ProcessingException('Failed to send records to processing: ${e.toString()}');
    }
  }
}