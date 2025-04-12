import 'package:equatable/equatable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/scan_record_entity.dart';

abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

class ScanInitial extends ScanState {}

class ScanningState extends ScanState {
  final bool isCameraActive;
  final bool isTorchEnabled;
  final MobileScannerController? controller;
  final List<List<String>> scannedItems;

  const ScanningState({
    required this.isCameraActive,
    required this.isTorchEnabled,
    this.controller,
    required this.scannedItems,
  });

  @override
  List<Object?> get props => [
    isCameraActive,
    isTorchEnabled,
    controller,
    scannedItems,
  ];

  ScanningState copyWith({
    bool? isCameraActive,
    bool? isTorchEnabled,
    MobileScannerController? controller,
    List<List<String>>? scannedItems,
  }) {
    return ScanningState(
      isCameraActive: isCameraActive ?? this.isCameraActive,
      isTorchEnabled: isTorchEnabled ?? this.isTorchEnabled,
      controller: controller ?? this.controller,
      scannedItems: scannedItems ?? this.scannedItems,
    );
  }
}

class MaterialInfoLoaded extends ScanState {
  final bool isCameraActive;
  final bool isTorchEnabled;
  final MobileScannerController? controller;
  final List<List<String>> scannedItems;
  final Map<String, String> materialInfo;
  final String currentBarcode;

  const MaterialInfoLoaded({
    required this.isCameraActive,
    required this.isTorchEnabled,
    this.controller,
    required this.scannedItems,
    required this.materialInfo,
    required this.currentBarcode,
  });

  @override
  List<Object?> get props => [
    isCameraActive,
    isTorchEnabled,
    controller,
    scannedItems,
    materialInfo,
    currentBarcode,
  ];

  MaterialInfoLoaded copyWith({
    bool? isCameraActive,
    bool? isTorchEnabled,
    MobileScannerController? controller,
    List<List<String>>? scannedItems,
    Map<String, String>? materialInfo,
    String? currentBarcode,
  }) {
    return MaterialInfoLoaded(
      isCameraActive: isCameraActive ?? this.isCameraActive,
      isTorchEnabled: isTorchEnabled ?? this.isTorchEnabled,
      controller: controller ?? this.controller,
      scannedItems: scannedItems ?? this.scannedItems,
      materialInfo: materialInfo ?? this.materialInfo,
      currentBarcode: currentBarcode ?? this.currentBarcode,
    );
  }
}

class SavingDataState extends ScanState {
  final bool isCameraActive;
  final bool isTorchEnabled;
  final MobileScannerController? controller;
  final List<List<String>> scannedItems;
  final Map<String, String> materialInfo;
  final String currentBarcode;

  const SavingDataState({
    required this.isCameraActive,
    required this.isTorchEnabled,
    this.controller,
    required this.scannedItems,
    required this.materialInfo,
    required this.currentBarcode,
  });

  @override
  List<Object?> get props => [
    isCameraActive,
    isTorchEnabled,
    controller,
    scannedItems,
    materialInfo,
    currentBarcode,
  ];
}

class DataSavedState extends ScanState {
  final ScanRecordEntity savedRecord;
  final List<List<String>> scannedItems;

  const DataSavedState({required this.savedRecord, required this.scannedItems});

  @override
  List<Object> get props => [savedRecord, scannedItems];
}

  class ScanProcessingState extends ScanState {
    final String barcode;

    const ScanProcessingState({required this.barcode});

    @override
    List<Object> get props => [barcode];
  }

class SendingToProcessingState extends ScanState {
  final List<ScanRecordEntity> records;

  const SendingToProcessingState({required this.records});

  @override
  List<Object> get props => [records];
}

class ScanErrorState extends ScanState {
  final String message;
  final ScanState previousState;

  const ScanErrorState({required this.message, required this.previousState});

  @override
  List<Object> get props => [message, previousState];
}

class ProcessingCompleteState extends ScanState {
  const ProcessingCompleteState();
}

class ScannerReadyState extends ScanState {}

class ScannerErrorState extends ScanState {
  final String message;

  const ScannerErrorState({required this.message});

  @override
  List<Object> get props => [message];
}

class ScanInitializingState extends ScanState {
  @override
  List<Object> get props => [];
}

class ShowClearConfirmationState extends ScanState {
  final ScanState previousState;

  const ShowClearConfirmationState({required this.previousState});

  @override
  List<Object> get props => [previousState];
}