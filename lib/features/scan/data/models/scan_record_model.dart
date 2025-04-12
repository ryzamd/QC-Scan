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
    required super.qcQtyOut,
    required super.qcQtyIn,
  });

  factory ScanRecordModel.fromJson(Map<String, dynamic> json) => _$ScanRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScanRecordModelToJson(this);

  static List<ScanRecordModel> dummyRecords = [];

  factory ScanRecordModel.create({
    required String code,
    required String status,
    required String quantity,
    required String userId,
    required Map<String, String> materialInfo,
    required double qcQtyOut,
    required double qcQtyIn,
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
      qcQtyIn: qcQtyIn,
    );
  }
}