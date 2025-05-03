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
  final List<List<String>> scannedItems;

  const ScanningState({
    required this.scannedItems,
  });

  @override
  List<Object?> get props => [
    scannedItems,
  ];

  ScanningState copyWith({
    List<List<String>>? scannedItems,
  }) {
    return ScanningState(
      scannedItems: scannedItems ?? this.scannedItems,
    );
  }
}

class MaterialInfoLoaded extends ScanState {
  final List<List<String>> scannedItems;
  final Map<String, String> materialInfo;
  final String currentBarcode;

  const MaterialInfoLoaded({
    required this.scannedItems,
    required this.materialInfo,
    required this.currentBarcode,
  });
  
  @override
  List<Object?> get props => [scannedItems, materialInfo, currentBarcode];
}

class SavingDataState extends ScanState {
  final MobileScannerController? controller;
  final List<List<String>> scannedItems;
  final Map<String, String> materialInfo;
  final String currentBarcode;

  const SavingDataState({
    this.controller,
    required this.scannedItems,
    required this.materialInfo,
    required this.currentBarcode,
  });

  @override
  List<Object?> get props => [
    controller,
    scannedItems,
    materialInfo,
    currentBarcode,
  ];
}

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

  const ScanErrorState({
    required this.message,
    required this.previousState,
  });

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

class ReasonsLoadingState extends ScanState {
  final ScanState baseState;
  
  const ReasonsLoadingState({required this.baseState});
  
  @override
  List<Object> get props => [baseState];
}

class ReasonsLoadedState extends ScanState {
  final ScanState baseState;
  final List<String> availableReasons;
  final List<String> selectedReasons;
  
  const ReasonsLoadedState({
    required this.baseState,
    required this.availableReasons,
    this.selectedReasons = const [],
  });
  
  @override
  List<Object> get props => [baseState, availableReasons, selectedReasons];
  
  ReasonsLoadedState copyWith({
    ScanState? baseState,
    List<String>? availableReasons,
    List<String>? selectedReasons,
  }) {
    return ReasonsLoadedState(
      baseState: baseState ?? this.baseState,
      availableReasons: availableReasons ?? this.availableReasons,
      selectedReasons: selectedReasons ?? this.selectedReasons,
    );
  }
}