// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessingItemModel _$ProcessingItemModelFromJson(Map<String, dynamic> json) =>
    ProcessingItemModel(
      mwhId: (json['mwhId'] as num).toInt(),
      mName: json['mName'] as String,
      mDate: json['mDate'] as String,
      mVendor: json['mVendor'] as String,
      mPrjcode: json['mPrjcode'] as String,
      mQty: (json['mQty'] as num).toDouble(),
      mUnit: json['mUnit'] as String,
      mDocnum: json['mDocnum'] as String,
      mItemcode: json['mItemcode'] as String,
      cDate: json['cDate'] as String,
      code: json['code'] as String,
      staff: json['staff'] as String?,
      qcCheckTime: json['qcCheckTime'] as String?,
      qcScanTime: json['qcScanTime'] as String?,
      qcQtyIn: (json['qcQtyIn'] as num).toInt(),
      qcQtyOut: (json['qcQtyOut'] as num).toInt(),
      zcWarehouseQtyInt: (json['zcWarehouseQtyInt'] as num).toInt(),
      zcWarehouseQtyOut: (json['zcWarehouseQtyOut'] as num).toInt(),
      zcWarehouseTimeInt: json['zcWarehouseTimeInt'] as String?,
      zcWarehouseTimeOut: json['zcWarehouseTimeOut'] as String?,
      zcOutWarehouseUnit: json['zcOutWarehouseUnit'] as String?,
      zcUpInQtyTime: json['zcUpInQtyTime'] as String?,
      qcUpInQtyTime: json['qcUpInQtyTime'] as String?,
      zcInQcQtyTime: json['zcInQcQtyTime'] as String?,
      qtyState: json['qtyState'] as String,
      adminAllDataTime: json['adminAllDataTime'] as String?,
      codeBonded: json['codeBonded'] as String?,
      status: $enumDecode(_$SignalStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$ProcessingItemModelToJson(
  ProcessingItemModel instance,
) => <String, dynamic>{
  'mwhId': instance.mwhId,
  'mName': instance.mName,
  'mDate': instance.mDate,
  'mVendor': instance.mVendor,
  'mPrjcode': instance.mPrjcode,
  'mQty': instance.mQty,
  'mUnit': instance.mUnit,
  'mDocnum': instance.mDocnum,
  'mItemcode': instance.mItemcode,
  'cDate': instance.cDate,
  'code': instance.code,
  'staff': instance.staff,
  'qcCheckTime': instance.qcCheckTime,
  'qcScanTime': instance.qcScanTime,
  'qcQtyIn': instance.qcQtyIn,
  'qcQtyOut': instance.qcQtyOut,
  'zcWarehouseQtyInt': instance.zcWarehouseQtyInt,
  'zcWarehouseQtyOut': instance.zcWarehouseQtyOut,
  'zcWarehouseTimeInt': instance.zcWarehouseTimeInt,
  'zcWarehouseTimeOut': instance.zcWarehouseTimeOut,
  'zcOutWarehouseUnit': instance.zcOutWarehouseUnit,
  'zcUpInQtyTime': instance.zcUpInQtyTime,
  'qcUpInQtyTime': instance.qcUpInQtyTime,
  'zcInQcQtyTime': instance.zcInQcQtyTime,
  'qtyState': instance.qtyState,
  'adminAllDataTime': instance.adminAllDataTime,
  'codeBonded': instance.codeBonded,
  'status': _$SignalStatusEnumMap[instance.status]!,
};

const _$SignalStatusEnumMap = {
  SignalStatus.pending: 'pending',
  SignalStatus.success: 'success',
  SignalStatus.failed: 'failed',
};
