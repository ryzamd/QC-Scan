// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessingItemModel _$ProcessingItemModelFromJson(Map<String, dynamic> json) =>
    ProcessingItemModel(
      itemName: json['itemName'] as String,
      orderNumber: json['orderNumber'] as String,
      quantity: (json['quantity'] as num).toInt(),
      exception: (json['exception'] as num).toInt(),
      timestamp: json['timestamp'] as String,
      status: $enumDecode(_$SignalStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$ProcessingItemModelToJson(
  ProcessingItemModel instance,
) => <String, dynamic>{
  'itemName': instance.itemName,
  'orderNumber': instance.orderNumber,
  'quantity': instance.quantity,
  'exception': instance.exception,
  'timestamp': instance.timestamp,
  'status': _$SignalStatusEnumMap[instance.status]!,
};

const _$SignalStatusEnumMap = {
  SignalStatus.pending: 'pending',
  SignalStatus.success: 'success',
  SignalStatus.failed: 'failed',
};
