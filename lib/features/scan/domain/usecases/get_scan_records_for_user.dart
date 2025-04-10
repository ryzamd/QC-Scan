import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_record_entity.dart';
import '../repositories/scan_repository.dart';

class GetScanRecordsForUser {
  final ScanRepository repository;

  GetScanRecordsForUser(this.repository);

  Future<Either<Failure, List<ScanRecordEntity>>> call(GetScanRecordsForUserParams params) async {
    return await repository.getScanRecordsForUserRepositoryAsync(params.userId);
  }
}

class GetScanRecordsForUserParams extends Equatable {
  final String userId;

  const GetScanRecordsForUserParams({required this.userId});

  @override
  List<Object> get props => [userId];
}