import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'processing_item_model.g.dart';

@JsonSerializable()
class ProcessingItemModel extends ProcessingItemEntity {
  const ProcessingItemModel({
    required super.mwhId,
    required super.mName,
    required super.mDate,
    required super.mVendor,
    required super.mPrjcode,
    required super.mQty,
    required super.mUnit,
    required super.mDocnum,
    required super.mItemcode,
    required super.cDate,
    required super.code,
    super.staff,
    super.qcCheckTime,
    super.qcScanTime,
    required super.qcQtyIn,
    required super.qcQtyOut,
    required super.zcWarehouseQtyInt,
    required super.zcWarehouseQtyOut,
    super.zcWarehouseTimeInt,
    super.zcWarehouseTimeOut,
    super.zcOutWarehouseUnit,
    super.zcUpInQtyTime,
    super.qcUpInQtyTime,
    super.zcInQcQtyTime,
    required super.qtyState,
    super.adminAllDataTime,
    super.codeBonded,
    required super.status,
  });

  factory ProcessingItemModel.fromJson(Map<String, dynamic> json) =>
      _$ProcessingItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingItemModelToJson(this);
}
