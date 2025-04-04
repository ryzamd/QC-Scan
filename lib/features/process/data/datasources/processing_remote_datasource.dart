// lib/features/process/data/datasources/processing_remote_datasource.dart
import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/di/dependencies.dart';
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/processing_item_model.dart';

abstract class ProcessingRemoteDataSource {

  Future<List<ProcessingItemModel>> getProcessingItems(String userName);

  Future<Map<String, dynamic>> saveQC2Deduction(String code, String userName, double deduction);
  
  /// Refresh processing items from the server
  ///
  /// Throws [ServerException] for all server-related errors
  // Future<List<ProcessingItemModel>> refreshProcessingItems();
}

class ProcessingRemoteDataSourceImpl implements ProcessingRemoteDataSource {
  final Dio dio;
  final bool useMockData; // Flag để bật/tắt mock data

  ProcessingRemoteDataSourceImpl({required this.dio, required this.useMockData});


 @override
  Future<List<ProcessingItemModel>> getProcessingItems(String userName) async {

     final token = await sl<SecureStorageService>().getAccessToken();
     
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Create mock data with new API structure
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
    // Make sure we're using POST with correct format
    final response = await dio.post(
      ApiConstants.homeListUrl,
      data: {"name": userName}, // Ensure this exact format matches Postman
      options: Options(
        headers: {"Authorization": "Bearer $token"},
        
        contentType: 'application/json',
        extra: {'log_request': true}
      ),
    );
    
    // Add detailed logging
    debugPrint('Processing API response code: ${response.statusCode}');
    debugPrint('Processing API response headers: ${response.headers}');
    debugPrint('Processing API response data type: ${response.data.runtimeType}');
    
    if (response.statusCode == 200) {
      final List<dynamic> itemsJson = response.data;
      final result = itemsJson.map((itemJson) =>
        ProcessingItemModel.fromJson(itemJson)
      ).toList();
      
      return result;
    } else {
      throw ServerException('Failed to load processing items: ${response.statusCode}');
    }
  } on DioException catch (e) {
    debugPrint('DioException in getProcessingItems: ${e.message}');
    debugPrint('Request path: ${e.requestOptions.path}');
    debugPrint('Request headers: ${e.requestOptions.headers}');
    debugPrint('Request method: ${e.requestOptions.method}');
    debugPrint('Request data: ${e.requestOptions.data}');
    throw ServerException(e.message ?? 'Error fetching processing items');
  } catch (e) {
    debugPrint('Unexpected error in getProcessingItems: $e');
    throw ServerException(e.toString());
  }
}

  @override
  Future<Map<String, dynamic>> saveQC2Deduction(String code, String userName, double deduction) async {
    try {
      final response = await dio.post(
        ApiConstants.saveQC2DeductionUrl,
        data: {
          'post_qc_code': code,
          'post_qc_UserName': userName,
          'post_qc_qty': deduction,
        },
      );
      
      debugPrint('QC2Deduction response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data['message'] == 'Success') {
          return response.data;
        } else {

          if (response.data['message'] == 'Too large a quantity') {
            throw ServerException('Error: ${response.data['error'] ?? 'La cantidad ingresada excede el límite permitido'}');
          }

          throw ServerException(response.data['error'] ?? response.data['message'] ?? 'Unknown error');
        }
      } else {
        throw ServerException('Failed to save QC2 deduction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException in saveQC2Deduction: ${e.message}');
      debugPrint('Request path: ${e.requestOptions.path}');
      debugPrint('Request data: ${e.requestOptions.data}');
      throw ServerException(e.message ?? 'Error processing QC2 deduction');
    } catch (e) {
      debugPrint('Unexpected error in saveQC2Deduction: $e');
      throw ServerException(e.toString());
    }
  }
  
  // @override
  // Future<List<ProcessingItemModel>> refreshProcessingItems() async {
  //   if (useMockData) {
  //     // Simulate network delay
  //     await Future.delayed(const Duration(seconds: 1));
      
  //     // Return mock data with slight changes to simulate refresh
  //     final refreshedItems = List<ProcessingItemModel>.from(mockItems)..shuffle();
  //     return refreshedItems;
  //   }

  //   try {
  //     final response = await dio.get('/api/processing/items/refresh');
      
  //     if (response.statusCode == 200) {
  //       final List<dynamic> itemsJson = response.data['items'];
  //       return itemsJson.map((itemJson) => ProcessingItemModel.fromJson(itemJson)).toList();
  //     } else {
  //       throw ServerException('Failed to refresh processing items');
  //     }
  //   } on DioException catch (e) {
  //     throw ServerException(e.message ?? 'Error refreshing processing items');
  //   } catch (e) {
  //     throw ServerException(e.toString());
  //   }
  // }
}