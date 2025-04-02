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

  // Remove the fromJson factory constructor if not needed
  factory ProcessingItemModel.fromJson(Map<String, dynamic> json) =>
      _$ProcessingItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingItemModelToJson(this);
}
