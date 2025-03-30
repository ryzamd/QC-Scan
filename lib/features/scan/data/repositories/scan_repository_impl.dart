// lib/features/scan/data/repositories/scan_repository_impl.dart
import 'package:architecture_scan_app/core/errors/scan_exceptions.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
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
        final materialInfo = await remoteDataSource.getMaterialInfo(barcode);
        return Right(materialInfo);
      } on MaterialNotFoundException catch (_) {
        return Left(ServerFailure('No material found for barcode: $barcode'));
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