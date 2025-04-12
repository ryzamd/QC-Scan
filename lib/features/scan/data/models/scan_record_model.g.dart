// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanRecordModel _$ScanRecordModelFromJson(Map<String, dynamic> json) =>
    ScanRecordModel(
      id: json['id'] as String,
      code: json['code'] as String,
      status: json['status'] as String,
      quantity: json['quantity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
      materialInfo: Map<String, String>.from(json['materialInfo'] as Map),
      qcQtyOut: json['qc_qty_out'] != null ? (json['qc_qty_out'] as double ).toDouble() : 0.0,
      qcQtyIn: json['qc_qty_in'] != null ? (json['qc_qty_in'] as double ).toDouble() : 0.0,
    );

Map<String, dynamic> _$ScanRecordModelToJson(ScanRecordModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'status': instance.status,
      'quantity': instance.quantity,
      'timestamp': instance.timestamp.toIso8601String(),
      'userId': instance.userId,
      'materialInfo': instance.materialInfo,
      'deduction_qc2' : instance.qcQtyOut,
      'deduction_qc1' : instance.qcQtyIn,
    };
