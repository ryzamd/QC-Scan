// lib/features/process/data/datasources/processing_remote_datasource.dart
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import '../models/processing_item_model.dart';

abstract class ProcessingRemoteDataSource {
  /// Get all processing items from the server
  ///
  /// Throws [ServerException] for all server-related errors
  Future<List<ProcessingItemModel>> getProcessingItems();
  
  /// Refresh processing items from the server
  ///
  /// Throws [ServerException] for all server-related errors
  Future<List<ProcessingItemModel>> refreshProcessingItems();
}

// lib/features/process/data/datasources/processing_remote_datasource.dart

class ProcessingRemoteDataSourceImpl implements ProcessingRemoteDataSource {
  final Dio dio;
  final bool useMockData; // Flag để bật/tắt mock data

  ProcessingRemoteDataSourceImpl({required this.dio, required this.useMockData});

  // Mock data
  static List<ProcessingItemModel> get mockItems => [
    ProcessingItemModel(
      itemName: 'Purple Lilac 13-4-11',
      orderNumber: 'P-452049',
      quantity: 50,
      exception: 0,
      timestamp: '2024-03-04 10:36:48.210479',
      status: SignalStatus.success,
    ),
  ];

  @override
  Future<List<ProcessingItemModel>> getProcessingItems() async {
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      return mockItems;
    }

    try {
      final response = await dio.get('/api/processing/items');
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = response.data['items'];
        return itemsJson.map((itemJson) => ProcessingItemModel.fromJson(itemJson)).toList();
      } else {
        throw ServerException('Failed to load processing items');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Error fetching processing items');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<ProcessingItemModel>> refreshProcessingItems() async {
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Return mock data with slight changes to simulate refresh
      final refreshedItems = List<ProcessingItemModel>.from(mockItems)..shuffle();
      return refreshedItems;
    }

    try {
      final response = await dio.get('/api/processing/items/refresh');
      
      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = response.data['items'];
        return itemsJson.map((itemJson) => ProcessingItemModel.fromJson(itemJson)).toList();
      } else {
        throw ServerException('Failed to refresh processing items');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Error refreshing processing items');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}