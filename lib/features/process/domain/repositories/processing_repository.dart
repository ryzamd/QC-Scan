// lib/features/process/domain/repositories/processing_repository.dart
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ProcessingRepository {
  
  Future<Either<Failure, List<ProcessingItemEntity>>> getProcessingItems(String date);

  Future<Either<Failure, ProcessingItemEntity>> updateQC2Quantity(String code, String userName, double deduction);
  
  /// Refresh processing items from remote source
  ///
  /// Returns list of [ProcessingItemEntity] if successful, [Failure] otherwise
  // Future<Either<Failure, List<ProcessingItemEntity>>> refreshProcessingItems();
}