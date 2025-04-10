// lib/features/process/domain/repositories/processing_repository.dart
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ProcessingRepository {
  
  Future<Either<Failure, List<ProcessingItemEntity>>> getProcessingItemsRepositoryAsync(String date);

  Future<Either<Failure, ProcessingItemEntity>> updateQC2QuantityRepositoryAsync(String code, String userName, double deduction);

}