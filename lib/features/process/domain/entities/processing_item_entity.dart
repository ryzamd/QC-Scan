import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:equatable/equatable.dart';

class ProcessingItemEntity extends Equatable {
  final int mwhId;
  final String? mName;
  final String? mDate;
  final String? mVendor;
  final String? mPrjcode;
  final double? mQty;
  final String? mUnit;
  final String? mDocnum;
  final String? mItemcode;
  final String? cDate;
  final String? code;
  final String? staff;
  final String? qcCheckTime;
  final String? qcScanTime;
  final double? qcQtyIn;
  final double? qcQtyOut;
  final double? zcWarehouseQtyInt;
  final double? zcWarehouseQtyOut;
  final String? zcWarehouseTimeInt;
  final String? zcWarehouseTimeOut;
  final String? zcOutWarehouseUnit;
  final String? zcUpInQtyTime;
  final String? qcUpInQtyTime;
  final String? zcInQcQtyTime;
  final String? qtyState;
  final String? adminAllDataTime;
  final String? codeBonded;
  final SignalStatus status;

  const ProcessingItemEntity({
    required this.mwhId,
    required this.mName,
    required this.mDate,
    required this.mVendor,
    required this.mPrjcode,
    required this.mQty,
    required this.mUnit,
    required this.mDocnum,
    required this.mItemcode,
    required this.cDate,
    required this.code,
    this.staff,
    this.qcCheckTime,
    this.qcScanTime,
    required this.qcQtyIn,
    required this.qcQtyOut,
    required this.zcWarehouseQtyInt,
    required this.zcWarehouseQtyOut,
    this.zcWarehouseTimeInt,
    this.zcWarehouseTimeOut,
    this.zcOutWarehouseUnit,
    this.zcUpInQtyTime,
    this.qcUpInQtyTime,
    this.zcInQcQtyTime,
    required this.qtyState,
    this.adminAllDataTime,
    this.codeBonded,
    required this.status,
  });

  @override
  List<Object?> get props => [
        mwhId,
        mName,
        mDate,
        mVendor,
        mPrjcode,
        mQty,
        mUnit,
        mDocnum,
        mItemcode,
        cDate,
        code,
        staff,
        qcCheckTime,
        qcScanTime,
        qcQtyIn,
        qcQtyOut,
        zcWarehouseQtyInt,
        zcWarehouseQtyOut,
        zcWarehouseTimeInt,
        zcWarehouseTimeOut,
        zcOutWarehouseUnit,
        zcUpInQtyTime,
        qcUpInQtyTime,
        zcInQcQtyTime,
        qtyState,
        adminAllDataTime,
        codeBonded,
        status,
      ];
}