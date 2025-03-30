import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_record_entity.dart';
import '../repositories/scan_repository.dart';

class SaveScanRecord {
  final ScanRepository repository;

  SaveScanRecord(this.repository);

  /// Execute the save scan record use case
  Future<Either<Failure, ScanRecordEntity>> call(SaveScanRecordParams params) async {
    return await repository.saveScanRecord(params.record);
  }
}

class SaveScanRecordParams extends Equatable {
  final ScanRecordEntity record;

  const SaveScanRecordParams({required this.record});

  @override
  List<Object> get props => [record];
}