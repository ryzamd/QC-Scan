import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_record_entity.dart';
import '../repositories/scan_repository.dart';

class SendToProcessing {
  final ScanRepository repository;

  SendToProcessing(this.repository);

  /// Execute the send to processing use case
  Future<Either<Failure, bool>> call(SendToProcessingParams params) async {
    return await repository.sendToProcessing(params.records);
  }
}

class SendToProcessingParams extends Equatable {
  final List<ScanRecordEntity> records;

  const SendToProcessingParams({required this.records});

  @override
  List<Object> get props => [records];
}
