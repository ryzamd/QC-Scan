// lib/features/process/data/datasources/processing_remote_datasource.dart
import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import '../models/processing_item_model.dart';

abstract class ProcessingRemoteDataSource {
  /// Get all processing items from the server with userName
  ///
  /// Throws [ServerException] for all server-related errors
  Future<List<ProcessingItemModel>> getProcessingItems(String userName);
  
  /// Refresh processing items from the server
  ///
  /// Throws [ServerException] for all server-related errors
  // Future<List<ProcessingItemModel>> refreshProcessingItems();
}

// lib/features/process/data/datasources/processing_remote_datasource.dart

class ProcessingRemoteDataSourceImpl implements ProcessingRemoteDataSource {
  final Dio dio;
  final bool useMockData; // Flag để bật/tắt mock data

  ProcessingRemoteDataSourceImpl({required this.dio, required this.useMockData});


 @override
  Future<List<ProcessingItemModel>> getProcessingItems(String userName) async {
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
      final response = await dio.get(
        'http://192.168.6.141:7053/api/login/data_list/user_name?name=$userName',
        data: {'name': userName},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = response.data;
        return itemsJson.map((itemJson) => ProcessingItemModel.fromJson(itemJson)).toList();
      } else {
        throw ServerException('Failed to load processing items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Error fetching processing items');
    } catch (e) {
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