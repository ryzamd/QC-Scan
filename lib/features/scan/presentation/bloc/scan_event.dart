// lib/features/scan/presentation/bloc/scan_event.dart
import 'package:equatable/equatable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

/// Event fired when a barcode is detected
class BarcodeDetected extends ScanEvent {
  final String barcode;

  const BarcodeDetected(this.barcode);

  @override
  List<Object> get props => [barcode];
}

/// Event fired when camera is toggled on/off
class ToggleCamera extends ScanEvent {
  final bool isActive;

  const ToggleCamera(this.isActive);

  @override
  List<Object> get props => [isActive];
}

/// Event fired when torch/flash is toggled
class ToggleTorch extends ScanEvent {
  final bool isEnabled;

  const ToggleTorch(this.isEnabled);

  @override
  List<Object> get props => [isEnabled];
}

/// Event fired when camera is switched (front/back)
class SwitchCamera extends ScanEvent {}

/// Event fired when material info is requested
class GetMaterialInfoEvent extends ScanEvent {
  final String barcode;

  const GetMaterialInfoEvent(this.barcode);

  @override
  List<Object> get props => [barcode];
}

/// Event fired when save button is pressed
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

/// Event fired when data is sent to processing
class SendToProcessingEvent extends ScanEvent {
  final String userId;

  const SendToProcessingEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Event fired to initialize scanner
class InitializeScanner extends ScanEvent {
  final MobileScannerController controller;

  const InitializeScanner(this.controller);

  @override
  List<Object> get props => [controller];
}

/// Event fired when a new scan is started
class StartNewScan extends ScanEvent {}

/// Event fired when hardware scanner button is pressed
class HardwareScanButtonPressed extends ScanEvent {
  final String scannedData;

  const HardwareScanButtonPressed(this.scannedData);

  @override
  List<Object> get props => [scannedData];
}