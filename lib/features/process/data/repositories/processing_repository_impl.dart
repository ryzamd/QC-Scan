import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/core/network/network_infor.dart';
import 'package:architecture_scan_app/features/process/data/datasources/processing_remote_datasource.dart';
import 'package:architecture_scan_app/features/process/data/models/processing_item_model.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/repositories/processing_repository.dart';
import 'package:dartz/dartz.dart';

class ProcessingRepositoryImpl implements ProcessingRepository {
  final ProcessingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProcessingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

   @override
  Future<Either<Failure, List<ProcessingItemEntity>>> getProcessingItemsRepositoryAsync(String date) async {
    if (await networkInfo.isConnected) {
      try {
        final processingItems = await remoteDataSource.getProcessingItemsRemoteDataAsync(date);
        return Right(processingItems);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }

  @override
  Future<Either<Failure, ProcessingItemEntity>> updateQC2QuantityRepositoryAsync(
    String code, String userName, double deduction) async {
    if (await networkInfo.isConnected) {
      try {
        
        final response = await remoteDataSource.saveQC2DeductionRemoteDataAsync(code, userName, deduction);

        return Right(ProcessingItemModel.fromJson(response));
        
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('No internet connection'));
    }
  }
}