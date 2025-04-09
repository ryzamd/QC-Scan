// lib/features/scan/domain/entities/scan_record_entity.dart
import 'package:equatable/equatable.dart';

/// Entity class for scan records
class ScanRecordEntity extends Equatable {
  final String id;
  final String code;
  final String status;
  final String quantity;
  final DateTime timestamp;
  final String userId;
  final Map<String, String> materialInfo;
  final double qcQtyOut;

  const ScanRecordEntity({
    required this.id,
    required this.code,
    required this.status,
    required this.quantity,
    required this.timestamp,
    required this.userId,
    required this.materialInfo,
    required this.qcQtyOut
  });

  @override
  List<Object?> get props => [
    id,
    code,
    status,
    quantity,
    timestamp,
    userId,
    materialInfo,
    qcQtyOut
  ];
}
