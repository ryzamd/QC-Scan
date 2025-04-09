// lib/features/scan/data/models/scan_record_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/scan_record_entity.dart';

part 'scan_record_model.g.dart';

@JsonSerializable()
class ScanRecordModel extends ScanRecordEntity {
  const ScanRecordModel({
    required super.id,
    required super.code,
    required super.status,
    required super.quantity,
    required super.timestamp,
    required super.userId,
    required super.materialInfo,
    required super.qcQtyOut
  });

  factory ScanRecordModel.fromJson(Map<String, dynamic> json) => _$ScanRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScanRecordModelToJson(this);

  /// Dummy implementation to mock a database for testing
  static List<ScanRecordModel> dummyRecords = [];

  /// Factory constructor to create a new ScanRecordModel with generated ID and timestamp
  factory ScanRecordModel.create({
    required String code,
    required String status,
    required String quantity,
    required String userId,
    required Map<String, String> materialInfo,
    required double qcQtyOut,
  }) {
    return ScanRecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code,
      status: status,
      quantity: quantity,
      timestamp: DateTime.now(),
      userId: userId,
      materialInfo: materialInfo,
      qcQtyOut: qcQtyOut,
    );
  }
}