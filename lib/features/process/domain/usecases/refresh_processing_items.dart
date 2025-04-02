// lib/features/process/domain/usecases/refresh_processing_items.dart
// import 'package:architecture_scan_app/core/errors/failures.dart';
// import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
// import 'package:architecture_scan_app/features/process/domain/repositories/processing_repository.dart';
// import 'package:dartz/dartz.dart';
// import 'package:equatable/equatable.dart';

// class RefreshProcessingItems {
//   final ProcessingRepository repository;

//   RefreshProcessingItems(this.repository);

//   /// Execute the refresh processing items use case
//   Future<Either<Failure, List<ProcessingItemEntity>>> call(NoParams params) async {
//     return await repository.refreshProcessingItems();
//   }
// }

// class NoParams extends Equatable {
//   @override
//   List<Object> get props => [];
// }