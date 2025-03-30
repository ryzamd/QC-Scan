// lib/features/scan/presentation/bloc/scan_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/scan_record_entity.dart';
import '../../domain/usecases/get_material_info.dart';
import '../../domain/usecases/save_scan_record.dart';
import '../../domain/usecases/send_to_processing.dart';
import '../../data/models/scan_record_model.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../../data/datasources/scan_service_impl.dart';
import 'scan_event.dart';
import 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final GetMaterialInfo getMaterialInfo;
  final SaveScanRecord saveScanRecord;
  final SendToProcessing sendToProcessing;
  final UserEntity currentUser;

  MobileScannerController? scannerController;
  
  ScanBloc({
    required this.getMaterialInfo,
    required this.saveScanRecord,
    required this.sendToProcessing,
    required this.currentUser,
  }) : super(ScanInitial()) {
    on<InitializeScanner>(_onInitializeScanner);
    on<BarcodeDetected>(_onBarcodeDetected);
    on<ToggleCamera>(_onToggleCamera);
    on<ToggleTorch>(_onToggleTorch);
    on<SwitchCamera>(_onSwitchCamera);
    on<GetMaterialInfoEvent>(_onGetMaterialInfo);
    on<SaveScannedData>(_onSaveScannedData);
    on<SendToProcessingEvent>(_onSendToProcessing);
    on<StartNewScan>(_onStartNewScan);
    on<HardwareScanButtonPressed>(_onHardwareScanButtonPressed);
  }

  void _onInitializeScanner(InitializeScanner event, Emitter<ScanState> emit) {
    debugPrint("Initializing scanner");
    scannerController = event.controller;
    
    // Initialize the scanner service with the callback for hardware scanners
    ScanService.initializeScannerListener((scannedData) {
      add(HardwareScanButtonPressed(scannedData));
    });
    
    emit(ScanningState(
      isCameraActive: true,
      isTorchEnabled: false,
      controller: scannerController,
      scannedItems: [],
    ));
  }

  Future<void> _onBarcodeDetected(BarcodeDetected event, Emitter<ScanState> emit) async {
    debugPrint("Barcode detected: ${event.barcode}");
    
    // Check if the current state has scanned items
    final currentState = state;
    List<List<String>> scannedItems = [];
    
    if (currentState is ScanningState) {
      scannedItems = List.from(currentState.scannedItems);
    } else if (currentState is MaterialInfoLoaded) {
      scannedItems = List.from(currentState.scannedItems);
    }
    
    // Add to scanned items if not already present
    if (!scannedItems.any((item) => item.isNotEmpty && item[0] == event.barcode)) {
      scannedItems.add([event.barcode, 'Scanned', '1']);
    }
    
    // Fetch material info for the detected barcode
    add(GetMaterialInfoEvent(event.barcode));
  }

  void _onToggleCamera(ToggleCamera event, Emitter<ScanState> emit) {
    debugPrint("Toggle camera: ${event.isActive}");
    
    final currentState = state;
    if (currentState is ScanningState) {
      if (event.isActive) {
        scannerController?.start();
      } else {
        scannerController?.stop();
      }
      
      emit(currentState.copyWith(isCameraActive: event.isActive));
    } else if (currentState is MaterialInfoLoaded) {
      if (event.isActive) {
        scannerController?.start();
      } else {
        scannerController?.stop();
      }
      
      emit(currentState.copyWith(isCameraActive: event.isActive));
    }
  }

  void _onToggleTorch(ToggleTorch event, Emitter<ScanState> emit) {
    debugPrint("Toggle torch: ${event.isEnabled}");
    
    scannerController?.toggleTorch();
    
    final currentState = state;
    if (currentState is ScanningState) {
      emit(currentState.copyWith(isTorchEnabled: event.isEnabled));
    } else if (currentState is MaterialInfoLoaded) {
      emit(currentState.copyWith(isTorchEnabled: event.isEnabled));
    }
  }

  void _onSwitchCamera(SwitchCamera event, Emitter<ScanState> emit) {
    debugPrint("Switch camera");
    
    scannerController?.switchCamera();
  }

  Future<void> _onGetMaterialInfo(GetMaterialInfoEvent event, Emitter<ScanState> emit) async {
    debugPrint("Getting material info for: ${event.barcode}");
    
    final currentState = state;
    List<List<String>> scannedItems = [];
    bool isCameraActive = true;
    bool isTorchEnabled = false;
    
    if (currentState is ScanningState) {
      scannedItems = List.from(currentState.scannedItems);
      isCameraActive = currentState.isCameraActive;
      isTorchEnabled = currentState.isTorchEnabled;
    } else if (currentState is MaterialInfoLoaded) {
      scannedItems = List.from(currentState.scannedItems);
      isCameraActive = currentState.isCameraActive;
      isTorchEnabled = currentState.isTorchEnabled;
    }
    
    final result = await getMaterialInfo(GetMaterialInfoParams(barcode: event.barcode));
    
    result.fold(
      (failure) {
        emit(ScanErrorState(
          message: failure.message,
          previousState: currentState,
        ));
      },
      (materialInfo) {
        emit(MaterialInfoLoaded(
          isCameraActive: isCameraActive,
          isTorchEnabled: isTorchEnabled,
          controller: scannerController,
          scannedItems: scannedItems,
          materialInfo: materialInfo,
          currentBarcode: event.barcode,
        ));
      },
    );
  }

  Future<void> _onSaveScannedData(SaveScannedData event, Emitter<ScanState> emit) async {
    debugPrint("Saving scanned data: ${event.barcode}");
    
    final currentState = state;
    if (currentState is MaterialInfoLoaded) {
      // Create a new model
      emit(SavingDataState(
        isCameraActive: currentState.isCameraActive,
        isTorchEnabled: currentState.isTorchEnabled,
        controller: currentState.controller,
        scannedItems: currentState.scannedItems,
        materialInfo: currentState.materialInfo,
        currentBarcode: currentState.currentBarcode,
      ));
      
      final scanRecord = ScanRecordModel.create(
        code: event.barcode,
        status: 'Pending',
        quantity: event.quantity,
        userId: event.userId,
        materialInfo: event.materialInfo,
      );
      
      final result = await saveScanRecord(SaveScanRecordParams(record: scanRecord));
      
      result.fold(
        (failure) {
          emit(ScanErrorState(
            message: failure.message,
            previousState: currentState,
          ));
        },
        (savedRecord) {
          emit(DataSavedState(
            savedRecord: savedRecord,
            scannedItems: currentState.scannedItems,
          ));
          
          // Automatically send to processing after saving
          add(SendToProcessingEvent(currentUser.userId));
        },
      );
    }
  }

  Future<void> _onSendToProcessing(SendToProcessingEvent event, Emitter<ScanState> emit) async {
    debugPrint("Sending to processing for user: ${event.userId}");
    
    final currentState = state;
    
    if (currentState is DataSavedState) {
      final List<ScanRecordEntity> records = [currentState.savedRecord];
      
      emit(SendingToProcessingState(records: records));
      
      final result = await sendToProcessing(SendToProcessingParams(records: records));
      
      result.fold(
        (failure) {
          emit(ScanErrorState(
            message: failure.message,
            previousState: currentState,
          ));
        },
        (success) {
          emit(const ProcessingCompleteState());
          
          // Reset to scanning state after processing
          add(StartNewScan());
        },
      );
    }
  }

  void _onStartNewScan(StartNewScan event, Emitter<ScanState> emit) {
    debugPrint("Starting new scan");
    
    // Reset to scanning state
    emit(ScanningState(
      isCameraActive: true,
      isTorchEnabled: false,
      controller: scannerController,
      scannedItems: [],
    ));
    
    // Restart camera if needed
    scannerController?.start();
  }

  Future<void> _onHardwareScanButtonPressed(HardwareScanButtonPressed event, Emitter<ScanState> emit) async {
    debugPrint("Hardware scan button pressed: ${event.scannedData}");
    
    // Process the hardware scan the same way as a camera scan
    add(BarcodeDetected(event.scannedData));
  }
  
  @override
  Future<void> close() {
    // Clean up resources
    scannerController?.dispose();
    ScanService.disposeScannerListener();
    return super.close();
  }
}