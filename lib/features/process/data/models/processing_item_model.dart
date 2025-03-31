// lib/features/process/data/models/processing_item_model.dart
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'processing_item_model.g.dart';

@JsonSerializable()
class ProcessingItemModel extends ProcessingItemEntity {
  const ProcessingItemModel({
    required super.itemName,
    required super.orderNumber,
    required super.quantity,
    required super.exception,
    required super.timestamp,
    required super.status,
  });

  factory ProcessingItemModel.fromJson(Map<String, dynamic> json) {
    return ProcessingItemModel(
      itemName: json['itemName'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      quantity: json['quantity'] ?? 0,
      exception: json['exception'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'orderNumber': orderNumber,
      'quantity': quantity,
      'exception': exception,
      'timestamp': timestamp,
      'status': status.toString().split('.').last,
    };
  }

  static SignalStatus _parseStatus(String? status) {
    if (status == 'success') return SignalStatus.success;
    if (status == 'failed') return SignalStatus.failed;
    return SignalStatus.pending;
  }
}