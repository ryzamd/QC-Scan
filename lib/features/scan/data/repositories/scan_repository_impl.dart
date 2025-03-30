// lib/features/scan/data/repositories/scan_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/scan_exceptions.dart';
import '../../../../core/network/network_infor.dart';
import '../../domain/entities/scan_record_entity.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_local_datasource.dart';
import '../datasources/scan_remote_datasource.dart';
import '../models/scan_record_model.dart';

class ScanRepositoryImpl implements ScanRepository {
  final ScanLocalDataSource localDataSource;
  final ScanRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ScanRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ScanRecordEntity>> saveScanRecord(ScanRecordEntity record) async {
    try {
      final recordModel = record as ScanRecordModel;
      final savedRecord = await localDataSource.saveScanRecord(recordModel);
      return Right(savedRecord);
    } on ScanException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScanRecordEntity>>> getScanRecordsForUser(String userId) async {
    try {
      final records = await localDataSource.getScanRecordsForUser(userId);
      return Right(records);
    } on ScanException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getMaterialInfo(String barcode) async {
    if (await networkInfo.isConnected) {
      try {
        // First attempt to get material info from the remote data source
        final materialInfo = await remoteDataSource.getMaterialInfo(barcode);
        return Right(materialInfo);
      } on MaterialNotFoundException catch (_) {
        // If material not found remotely, generate mock data
        // This is only for demo purposes
        try {
          Map<String, String> mockInfo = {};
          if (barcode.contains('/')) {
            mockInfo = {
              'Material Name': '本白1-400ITPG 荷布DJT-8543 GUSTI TEX EPM 100% 315G 44"',
              'Material ID': barcode,
              'Quantity': '50.5',
              'Receipt Date': DateTime.now().toString().substring(0, 19),
              'Supplier': 'DONGJIN-USD',
            };
          } else {
            mockInfo = {
              'Material Name': 'Material ${barcode.hashCode % 1000}',
              'Material ID': barcode,
              'Quantity': '${(barcode.hashCode % 100).abs() + 10}',
              'Receipt Date': DateTime.now().toString().substring(0, 19),
              'Supplier': 'Supplier ${barcode.hashCode % 5 + 1}',
            };
          }
          return Right(mockInfo);
        } catch (e) {
          return Left(ServerFailure('Error generating mock data: ${e.toString()}'));
        }
      } on ScanException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }

  @override
  Future<Either<Failure, bool>> sendToProcessing(List<ScanRecordEntity> records) async {
    if (await networkInfo.isConnected) {
      try {
        final recordModels = records.map((record) => record as ScanRecordModel).toList();
        final success = await remoteDataSource.sendToProcessing(recordModels);
        
        if (success) {
          // Clear records after successful processing
          // This is optional and depends on your business logic
          // await localDataSource.clearScanRecordsForUser(records.first.userId);
          return const Right(true);
        } else {
          return Left(ServerFailure('Failed to send records to processing.'));
        }
      } on ProcessingException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }
}