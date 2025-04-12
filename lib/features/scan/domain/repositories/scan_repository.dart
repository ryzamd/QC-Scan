import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_record_entity.dart';

abstract class ScanRepository {
  Future<Either<Failure, ScanRecordEntity>> saveScanRecordRepositoryAsync(ScanRecordEntity record);
  
  Future<Either<Failure, List<ScanRecordEntity>>> getScanRecordsForUserRepositoryAsync(String userId);
  
  Future<Either<Failure, Map<String, String>>> getMaterialInfoRepositoryAsync(String barcode);

  Future<Either<Failure, bool>> sendToProcessingRepositoryAsync(List<ScanRecordEntity> records);
}