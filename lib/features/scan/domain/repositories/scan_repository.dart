// lib/features/scan/domain/repositories/scan_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_record_entity.dart';

abstract class ScanRepository {
  /// Save a scanned record to the repository
  ///
  /// Returns the saved [ScanRecordEntity] if successful, [Failure] otherwise
  Future<Either<Failure, ScanRecordEntity>> saveScanRecord(ScanRecordEntity record);
  
  /// Get all scan records for a specific user
  ///
  /// Returns a list of [ScanRecordEntity] if successful, [Failure] otherwise
  Future<Either<Failure, List<ScanRecordEntity>>> getScanRecordsForUser(String userId);
  
  /// Get material information based on a barcode
  ///
  /// Returns a Map of material information if successful, [Failure] otherwise
  Future<Either<Failure, Map<String, String>>> getMaterialInfo(String barcode);
  
  /// Send scan records to processing
  ///
  /// Returns true if successful, [Failure] otherwise
  Future<Either<Failure, bool>> sendToProcessing(List<ScanRecordEntity> records);
}