import 'package:equatable/equatable.dart';

class ScanRecordEntity extends Equatable {
  final String id;
  final String code;
  final String status;
  final String quantity;
  final DateTime timestamp;
  final String userId;
  final Map<String, String> materialInfo;
  final double qcQtyOut;
  final double qcQtyIn;

  const ScanRecordEntity({
    required this.id,
    required this.code,
    required this.status,
    required this.quantity,
    required this.timestamp,
    required this.userId,
    required this.materialInfo,
    required this.qcQtyOut,
    required this.qcQtyIn,
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
    qcQtyOut,
    qcQtyIn,
  ];
}
