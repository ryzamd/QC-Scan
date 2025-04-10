// lib/features/process/data/datasources/processing_remote_datasource.dart
import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/di/dependencies.dart';
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/processing_item_model.dart';

abstract class ProcessingRemoteDataSource {
  Future<List<ProcessingItemModel>> getProcessingItemsRemoteDataAsync(String date);
  Future<Map<String, dynamic>> saveQC2DeductionRemoteDataAsync(String code, String userName, double deduction);
}

class ProcessingRemoteDataSourceImpl implements ProcessingRemoteDataSource {
  final Dio dio;
  final bool useMockData;
  final token = sl<SecureStorageService>().getAccessTokenAsync();

  ProcessingRemoteDataSourceImpl({required this.dio, required this.useMockData});

  @override
  Future<List<ProcessingItemModel>> getProcessingItemsRemoteDataAsync(String date) async {
    final token = await sl<SecureStorageService>().getAccessTokenAsync();
     
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      return [
        ProcessingItemModel(
          mwhId: 1693,
          mName: "丁香紫13-4110TPG 網布 DJT-8540 ANTIO TEX (EPM 100%) 270G 44\"",
          mDate: "2024-03-02T00:00:00",
          mVendor: "DONGJIN-USD",
          mPrjcode: "P-452049",
          mQty: 50.5,
          mUnit: "碼/YRD",
          mDocnum: "75689",
          mItemcode: "CA0400076011019",
          cDate: "2024-03-04T10:36:48.586568",
          code: "9f60778799d34d70adaf8ba5adcb0dcd",
          qcQtyIn: 0,
          qcQtyOut: 0,
          zcWarehouseQtyInt: 0,
          zcWarehouseQtyOut: 0,
          qtyState: "未質檢",
          status: SignalStatus.pending,
        ),
      ];
    }

    try {
      final response = await dio.get(
        ApiConstants.getListUrl(date),
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          contentType: 'application/json',
          extra: {'log_request': true}
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = response.data;
        
        return compute(_parseProcessingItems, itemsJson);

      } else {
        throw ServerException('Failed to load processing items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException in getProcessingItems: ${e.message}');
      debugPrint('Request path: ${e.requestOptions.path}');
      throw ServerException(e.message ?? 'Error fetching processing items');
    } catch (e) {
      debugPrint('Unexpected error in getProcessingItems: $e');
      throw ServerException(e.toString());
    }
  }

  static List<ProcessingItemModel> _parseProcessingItems(List<dynamic> itemsJson) {
    return itemsJson.map((itemJson) => ProcessingItemModel.fromJson(itemJson)).toList();
  }

  @override
  Future<Map<String, dynamic>> saveQC2DeductionRemoteDataAsync(String code, String userName, double deduction) async {
    try {
      final response = await dio.post(
        ApiConstants.saveQC2DeductionUrl,
        data: {
          'post_qc_code': code,
          'post_qc_UserName': userName,
          'post_qc_qty': deduction,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          contentType: 'application/json',
          extra: {'log_request': true}
        ),
      );
      
      if (response.statusCode == 200) {
        return compute(_processDeductionResponse, response.data);

      } else {
        throw ServerException('Failed to save QC2 deduction: ${response.statusCode}');
        
      }
    } on DioException catch (e) {
      debugPrint('DioException in saveQC2Deduction: ${e.message}');
      throw ServerException('Error processing deduction');

    } catch (e) {
      debugPrint('Unexpected error in saveQC2Deduction: $e');
      throw ServerException(e.toString());

    }
  }
  
  static Map<String, dynamic> _processDeductionResponse(dynamic data) {
    if (data['message'] == 'Success') {
      return data;

    } else if (data['message'] == 'Too large a quantity') {
      throw ServerException('Error: ${data['error'] ?? 'La cantidad ingresada excede el límite permitido'}');

    } else {
      throw ServerException(data['error'] ?? data['message'] ?? 'Unknown error');
    }
  }
}