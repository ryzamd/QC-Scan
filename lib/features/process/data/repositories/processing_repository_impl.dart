// lib/features/process/data/repositories/processing_repository_impl.dart
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/core/network/network_infor.dart';
import 'package:architecture_scan_app/features/process/data/datasources/processing_remote_datasource.dart';
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
  Future<Either<Failure, List<ProcessingItemEntity>>> getProcessingItems() async {
    if (await networkInfo.isConnected) {
      try {
        final processingItems = await remoteDataSource.getProcessingItems();
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
  Future<Either<Failure, List<ProcessingItemEntity>>> refreshProcessingItems() async {
    if (await networkInfo.isConnected) {
      try {
        final processingItems = await remoteDataSource.refreshProcessingItems();
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
}