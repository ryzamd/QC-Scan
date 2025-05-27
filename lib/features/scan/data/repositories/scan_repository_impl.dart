import 'package:architecture_scan_app/core/services/get_translate_key.dart';
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
  Future<Either<Failure, ScanRecordEntity>> saveScanRecordRepositoryAsync(ScanRecordEntity record) async {
    try {
      final recordModel = record as ScanRecordModel;
      final savedRecord = await localDataSource.saveScanRecordLocalDataSourceAsync(recordModel);
      return Right(savedRecord);
    } on ScanException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScanRecordEntity>>> getScanRecordsForUserRepositoryAsync(String userId) async {
    try {
      final records = await localDataSource.getScanRecordsForUserLocalDataSourceAsync(userId);
      return Right(records);
    } on ScanException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getMaterialInfoRepositoryAsync(String barcode) async {
    if (await networkInfo.isConnected) {
      try {
        final materialInfo = await remoteDataSource.getMaterialInfoRemoteDataAsync(barcode, "品管質檢");
        return Right(materialInfo);

      } on MaterialNotFoundException catch (_) {
        return Left(ServerFailure(StringKey.materialNotFound));

      } on ScanException catch (e) {
        return Left(ServerFailure(e.message));

      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure(StringKey.networkErrorMessage));
    }
  }


  // @override
  // Future<Either<Failure, bool>> sendToProcessingRepositoryAsync(List<ScanRecordEntity> records) async {
  //   if (await networkInfo.isConnected) {
  //     try {
  //       if (records.isEmpty) {
  //         return const Left(ServerFailure('No records to process'));
  //       }
        
  //       final lastRecord = records.last;
  //       final String code = lastRecord.code;
  //       final String userName = lastRecord.userId;
  //       final double deduction = 0.0;
        
  //       final success = await remoteDataSource.saveQualityInspectionRemoteDataAsync(code, userName, deduction);
        
  //       return Right(success);

  //     } on ProcessingException catch (e) {
  //       return Left(ServerFailure(e.message));

  //     } catch (e) {
  //       return Left(ServerFailure(e.toString()));

  //     }
  //   } else {
  //     return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
      
  //   }
  // }
}