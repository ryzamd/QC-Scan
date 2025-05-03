import 'package:equatable/equatable.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

class BarcodeDetected extends ScanEvent {
  final String barcode;

  const BarcodeDetected(this.barcode);

  @override
  List<Object> get props => [barcode];
}

class GetMaterialInfoEvent extends ScanEvent {
  final String barcode;

  const GetMaterialInfoEvent(this.barcode);

  @override
  List<Object> get props => [barcode];
}

class SaveScannedData extends ScanEvent {
  final String barcode;
  final String quantity;
  final Map<String, String> materialInfo;
  final String userId;

  const SaveScannedData({
    required this.barcode,
    required this.quantity,
    required this.materialInfo,
    required this.userId,
  });

  @override
  List<Object> get props => [barcode, quantity, materialInfo, userId];
}

class HardwareScanButtonPressed extends ScanEvent {
  final String scannedData;

  const HardwareScanButtonPressed(this.scannedData);

  @override
  List<Object> get props => [scannedData];
}

class ConfirmDeductionEvent extends ScanEvent {
  final String barcode;
  final String quantity;
  final double deduction;
  final Map<String, String> materialInfo;
  final String userId;
  final double qcQtyOut;
  final double qcQtyIn;
  final bool isQC2User;
  final int? optionFunction;
  final List<String>? reasons;

  const ConfirmDeductionEvent({
    required this.barcode,
    required this.quantity,
    required this.deduction,
    required this.materialInfo,
    required this.userId,
    required this.qcQtyIn,
    required this.qcQtyOut,
    required this.isQC2User,
    this.optionFunction,
    this.reasons,
  });

  @override
  List<Object> get props => [barcode, quantity, deduction, materialInfo, userId, qcQtyOut,isQC2User, optionFunction!, reasons ?? []];
}

class InitializeScanService extends ScanEvent {}

class ClearScannedItems extends ScanEvent {}

class ShowClearConfirmationEvent extends ScanEvent {}

class ConfirmClearScannedItems  extends ScanEvent {}

class CancelClearScannedItems  extends ScanEvent {}

class ProcessQC2DeductionEvent extends ScanEvent {
  final String code;
  final String userName;
  final double deduction;
  final double currentQuantity;

  const ProcessQC2DeductionEvent({
    required this.code,
    required this.userName,
    required this.deduction,
    required this.currentQuantity,
  });

  @override
  List<Object> get props => [code, userName, deduction, currentQuantity];
}

class LoadReasonsEvent extends ScanEvent {}

class ReasonsSelectedEvent extends ScanEvent {
  final List<String> selectedReasons;
  
  const ReasonsSelectedEvent({required this.selectedReasons});
  
  @override
  List<Object> get props => [selectedReasons];
}