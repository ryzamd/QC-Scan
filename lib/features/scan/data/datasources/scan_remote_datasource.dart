import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/errors/scan_exceptions.dart';
import 'package:architecture_scan_app/core/services/get_translate_key.dart';
import 'package:dio/dio.dart';

abstract class ScanRemoteDataSource {
  Future<Map<String, String>> getMaterialInfoRemoteDataAsync(String code, String userName);

  Future<bool> saveQualityInspectionRemoteDataAsync(String code, String userName, double deduction, [List<String>? reasons]);

  Future<bool> saveQC2DeductionRemoteDataAsync(String code, String userName, double deduction, int optionFunction, [List<String>? reasons]);

   Future<List<String>> getDeductionReasonsAsync();
}

class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  final Dio dio;

  ScanRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, String>> getMaterialInfoRemoteDataAsync(
    String code,
    String userName,
  ) async {
    try {
      if (!dio.options.headers.containsKey('Authorization')) {
        throw AuthException('Missing authorization token');
      }

      final response = await dio.post(
        ApiConstants.checkCodeUrl,
        data: {
          'code': code,
          'user_name': userName,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['message'] == 'Success') {
          final materialData = response.data['data'];

          return {
            'Material Name': materialData['m_name'] ?? '',
            'Material ID': materialData['code'] ?? code,
            'Quantity': materialData['m_qty']?.toString() ?? '0',
            'Receipt Date': materialData['m_date'] ?? '',
            'Supplier': materialData['m_vendor'] ?? '',
            'Unit': materialData['m_unit'] ?? '',
            'Status': materialData['qty_state'] ?? '',
            'Deduction_QC2': materialData['qc_qty_out']?.toString() ?? '0',
            'Deduction_QC1': materialData['qc_qty_in']?.toString() ?? '0',
            'qc_reason': materialData['qc_reason'] ?? '',
          };
        } else {
          throw MaterialNotFoundException(code);
        }
      } else if (response.statusCode == 401) {
        throw AuthException(StringKey.invalidTokenMessage);

      } else {
        throw ServerException(StringKey.serverErrorMessage);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ScanException(StringKey.connectionTimeoutMessage);

      } else if (e.type == DioExceptionType.connectionError) {
        throw ScanException(StringKey.cannotConnectToServerMessage);

      } else {
        throw ScanException(StringKey.serverErrorMessage);
      }

    } catch (e) {
      throw ScanException(StringKey.failedToGetMaterialInfoMessage);
    }
  }

  @override
  Future<bool> saveQualityInspectionRemoteDataAsync(String code, String userName, double deduction, [List<String>? reasons]) async {
      try {
        final data = {
          'qc_code': code,
          'qc_UserName': userName,
          'qc_qty': deduction,
        };
        
        if (reasons != null && reasons.isNotEmpty) {
          data['reason'] = reasons.join(',');
        }

        final response = await dio.post(
          ApiConstants.saveQualityInspectionUrl,
          data: data,
        );
        
        if (response.statusCode == 200 && response.data['message'] == 'Success') {
        return true;

      } else {
        throw ProcessingException(response.data['message'] ?? StringKey.unknownErrorMessage);
      }
    } on DioException catch (_) {
      throw ScanException(StringKey.networkErrorMessage);

    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<bool> saveQC2DeductionRemoteDataAsync(String code, String userName, double deduction, int optionFunction, [List<String>? reasons]) async {
     try {
      final data = {
        'qc_code': code,
        'qc_UserName': userName,
        'qc_qty': deduction,
        'number': optionFunction,
      };
      
      if (reasons != null && reasons.isNotEmpty) {
        data['reason'] = reasons.join(',');
      }
      
      final response = await dio.post(
        ApiConstants.saveQC2DeductionUrl,
        data: data,
      );
      
      if (response.statusCode == 200 && response.data['message'] == 'Success') {
        return true;

      } else {
        throw ProcessingException(response.data['message'] ?? StringKey.unknownErrorMessage);
      }

    } on DioException catch (_) {
      throw ScanException(StringKey.networkErrorMessage);

    } catch (e) {
      throw ServerException(StringKey.serverErrorMessage);
    }
  }
  
  @override
  Future<List<String>> getDeductionReasonsAsync() async {
    try {
      final response = await dio.post(ApiConstants.getListReasonUrl);

      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return List<String>.from(response.data['addressList'] ?? []);
      }
      
      throw ProcessingException(StringKey.failedToGetDeductionReasons);

    } on DioException catch (_) {
      throw ScanException(StringKey.networkErrorMessage);

    } catch (e) {
      throw ServerException(StringKey.serverErrorMessage);
    }
  }
}