// lib/features/scan/data/datasources/scan_remote_datasource.dart
import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/errors/scan_exceptions.dart';
import 'package:dio/dio.dart';

abstract class ScanRemoteDataSource {
  /// Get material information from server based on scanned code
  ///
  /// Throws [MaterialNotFoundException] if material not found
  /// Throws [ScanException] if operation fails
  Future<Map<String, String>> getMaterialInfo(String code, String userName);

  /// Save quality inspection data with deduction
  ///
  /// Throws [ProcessingException] if processing fails
  Future<bool> saveQualityInspection(
    String code,
    String userName,
    double deduction,
  );
}

class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  final Dio dio;

  ScanRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, String>> getMaterialInfo(
    String code,
    String userName,
  ) async {
    try {
      // Check if token exists in headers
      if (!dio.options.headers.containsKey('Authorization')) {
        throw AuthException('Missing authorization token');
      }

      final response = await dio.post(
        ApiConstants.checkCodeUrl,
        data: {'code': code, 'user_name': userName},
      );

      if (response.statusCode == 200) {
        if (response.data['message'] == 'Success') {
          final materialData = response.data['data'];
          // Convert dynamic data to Map<String, String>
          return {
            'Material Name': materialData['m_name'] ?? '',
            'Material ID': materialData['code'] ?? code,
            'Quantity': materialData['m_qty']?.toString() ?? '0',
            'Receipt Date': materialData['m_date'] ?? '',
            'Supplier': materialData['m_vendor'] ?? '',
            'Unit': materialData['m_unit'] ?? '',
            'Status': materialData['qty_state'] ?? '',
            // Lưu lại các trường gốc cần thiết
            'code': materialData['code'] ?? code,
            'm_name': materialData['m_name'] ?? '',
            'm_qty': materialData['m_qty']?.toString() ?? '0',
          };
        } else {
          throw MaterialNotFoundException(code);
        }
      } else if (response.statusCode == 401) {
           AuthException('Invalid or expired token');
      } else {
        throw ServerException(
          'Server returned error code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ScanException('Connection timeout. Please check your network.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw ScanException(
          'Cannot connect to server. Please check your network.',
        );
      }
      throw ScanException('Network error: ${e.message}');
    } catch (e) {
      if (e is MaterialNotFoundException) {
        rethrow;
      }
      throw ScanException('Failed to get material info: ${e.toString()}');
    }
    throw ScanException('Unexpected error occurred while fetching material info.');
  }

  @override
  Future<bool> saveQualityInspection(
    String code,
    String userName,
    double deduction,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.saveQualityInspectionUrl,
        data: {
          'post_no_qc_code': code,
          'post_no_qc_UserName': userName,
          'post_no_qc_qty': deduction,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['message'] == 'Success') {
          return true;
        } else {
          throw ProcessingException(
            'Failed to save quality inspection: ${response.data['message']}',
          );
        }
      } else {
        throw ServerException(
          'Server returned error code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProcessingException(
          'Connection timeout. Please check your network.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw ProcessingException(
          'Cannot connect to server. Please check your network.',
        );
      }
      throw ProcessingException('Network error: ${e.message}');
    } catch (e) {
      throw ProcessingException(
        'Failed to save quality inspection: ${e.toString()}',
      );
    }
  }
}
