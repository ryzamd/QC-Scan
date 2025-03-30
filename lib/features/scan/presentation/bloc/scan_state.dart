// lib/features/scan/presentation/bloc/scan_state.dart
import 'package:equatable/equatable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/scan_record_entity.dart';

abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

/// Initial state of the scan feature
class ScanInitial extends ScanState {}

/// State representing scanning in progress
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
  List<Object?> get props => [isCameraActive, isTorchEnabled, controller, scannedItems];

  /// Create a copy of this state with updated values
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

/// State representing material information retrieved from a scan
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
    currentBarcode
  ];

  /// Create a copy of this state with updated values
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

/// State representing data being saved
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
    currentBarcode
  ];
}

/// State representing data saved successfully
class DataSavedState extends ScanState {
  final ScanRecordEntity savedRecord;
  final List<List<String>> scannedItems;

  const DataSavedState({
    required this.savedRecord,
    required this.scannedItems,
  });

  @override
  List<Object> get props => [savedRecord, scannedItems];
}

/// State representing data being sent to processing
class SendingToProcessingState extends ScanState {
  final List<ScanRecordEntity> records;

  const SendingToProcessingState({
    required this.records,
  });

  @override
  List<Object> get props => [records];
}

/// State representing an error
class ScanErrorState extends ScanState {
  final String message;
  final ScanState previousState;

  const ScanErrorState({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object> get props => [message, previousState];
}

/// State representing processing complete
class ProcessingCompleteState extends ScanState {
  const ProcessingCompleteState();
}