import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/repositories/processing_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateQC2Quantity {
  final ProcessingRepository repository;

  UpdateQC2Quantity(this.repository);

  Future<Either<Failure, ProcessingItemEntity>> call(UpdateQC2QuantityParams params) async {

    if (params.deduction > params.currentQuantity) {
      return Left(ServerFailure('Deduction cannot exceed current quantity'));
    }

    if (params.deduction <= 0) {
      return Left(ServerFailure('Deduction must be greater than zero'));
    }
    
    return await repository.updateQC2QuantityRepositoryAsync(
      params.code,
      params.userName,
      params.deduction
    );
  }
}

class UpdateQC2QuantityParams extends Equatable {
  final String code;
  final String userName;
  final double deduction;
  final double currentQuantity;

  const UpdateQC2QuantityParams({
    required this.code,
    required this.userName,
    required this.deduction,
    required this.currentQuantity,
  });

  @override
  List<Object> get props => [code, userName, deduction, currentQuantity];
}