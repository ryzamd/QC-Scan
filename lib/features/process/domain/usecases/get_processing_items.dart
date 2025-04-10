import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/repositories/processing_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetProcessingItems {
  final ProcessingRepository repository;

  GetProcessingItems(this.repository);

  Future<Either<Failure, List<ProcessingItemEntity>>> call(GetProcessingParams params) async {
    return await repository.getProcessingItemsRepositoryAsync(params.date);
  }
}

class GetProcessingParams extends Equatable {
  final String date;

  const GetProcessingParams({required this.date});
  
  @override
  List<Object> get props => [date];
}