import 'package:equatable/equatable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

class ToggleCamera extends ScanEvent {
  final bool isActive;

  const ToggleCamera({required this.isActive});

  @override
  List<Object> get props => [isActive];
}

class ToggleTorch extends ScanEvent {
  final bool isEnabled;

  const ToggleTorch(this.isEnabled);

  @override
  List<Object> get props => [isEnabled];
}

class SwitchCamera extends ScanEvent {}

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

class SendToProcessingEvent extends ScanEvent {
  final String userId;

  const SendToProcessingEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class InitializeScanner extends ScanEvent {
  final MobileScannerController? controller;

  const InitializeScanner([this.controller]);

  @override
  List<Object?> get props => [controller];
}

class StartNewScan extends ScanEvent {}

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
  final int optionFunction;

  const ConfirmDeductionEvent({
    required this.barcode,
    required this.quantity,
    required this.deduction,
    required this.materialInfo,
    required this.userId,
    required this.qcQtyIn,
    required this.qcQtyOut,
    required this.optionFunction,
    required this.isQC2User,
  });

  @override
  List<Object> get props => [barcode, quantity, deduction, materialInfo, userId, qcQtyOut,isQC2User, optionFunction];
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