// lib/features/scan/presentation/bloc/scan_bloc.dart
import 'package:architecture_scan_app/core/di/dependencies.dart' as di;
import 'package:architecture_scan_app/core/services/processing_data_service.dart';
import 'package:architecture_scan_app/features/scan/data/datasources/scan_remote_datasource.dart';
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
  final ScanRemoteDataSource remoteDataSource;

  MobileScannerController? scannerController;

  ScanBloc({
    required this.remoteDataSource,
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
    on<ConfirmDeductionEvent>(_onConfirmDeduction);

  }

  void _onInitializeScanner(InitializeScanner event, Emitter<ScanState> emit) {
    debugPrint("ScanBloc: Initializing scanner");
    scannerController = event.controller;

    // Initialize the scanner service with the callback for hardware scanners
    ScanService.initializeScannerListener((scannedData) {
      debugPrint("ScanBloc: Hardware scanner data received: $scannedData");
      add(HardwareScanButtonPressed(scannedData));
    });

    emit(
      ScanningState(
        isCameraActive: true,
        isTorchEnabled: false,
        controller: scannerController,
        scannedItems: [],
      ),
    );
  }

  Future<void> _onBarcodeDetected(
    BarcodeDetected event,
    Emitter<ScanState> emit,
  ) async {
    debugPrint("ScanBloc: Barcode detected: ${event.barcode}");

    // Hiển thị trạng thái đang xử lý
    emit(ScanProcessingState(barcode: event.barcode));

    // Gọi API để lấy thông tin vật liệu
    final result = await getMaterialInfo(
      GetMaterialInfoParams(barcode: event.barcode),
    );

    result.fold(
      (failure) {
        debugPrint("ScanBloc: Error getting material info: ${failure.message}");
        emit(
          ScanErrorState(
            message: failure.message,
            previousState: state,
          ),
        );
      },
      (materialInfo) {
        debugPrint("ScanBloc: Successfully loaded material info");
        
        // Cập nhật scanned items
        List<List<String>> scannedItems = [];
        if (state is ScanningState) {
          scannedItems = List.from((state as ScanningState).scannedItems);
        } else if (state is MaterialInfoLoaded) {
          scannedItems = List.from((state as MaterialInfoLoaded).scannedItems);
        }
        
        // Thêm vào danh sách scanned items nếu chưa có
        final isAlreadyScanned = scannedItems.any(
          (item) => item.isNotEmpty && item[0] == event.barcode,
        );
        
        if (!isAlreadyScanned) {
          scannedItems.add([event.barcode, 'Scanned', materialInfo['Quantity'] ?? '0']);
        }
        
        emit(
          MaterialInfoLoaded(
            isCameraActive: state is ScanningState ? (state as ScanningState).isCameraActive : true,
            isTorchEnabled: state is ScanningState ? (state as ScanningState).isTorchEnabled : false,
            controller: scannerController,
            scannedItems: scannedItems,
            materialInfo: materialInfo,
            currentBarcode: event.barcode,
          ),
        );
      },
    );
  }

  void _onToggleCamera(ToggleCamera event, Emitter<ScanState> emit) {
    debugPrint("ScanBloc: Toggle camera: ${event.isActive}");

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
    debugPrint("ScanBloc: Toggle torch: ${event.isEnabled}");

    scannerController?.toggleTorch();

    final currentState = state;
    if (currentState is ScanningState) {
      emit(currentState.copyWith(isTorchEnabled: event.isEnabled));
    } else if (currentState is MaterialInfoLoaded) {
      emit(currentState.copyWith(isTorchEnabled: event.isEnabled));
    }
  }

  void _onSwitchCamera(SwitchCamera event, Emitter<ScanState> emit) {
    debugPrint("ScanBloc: Switch camera");

    scannerController?.switchCamera();
  }

  Future<void> _onGetMaterialInfo(
    GetMaterialInfoEvent event,
    Emitter<ScanState> emit,
  ) async {
    debugPrint("ScanBloc: Getting material info for: ${event.barcode}");

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

    // Assuming real repository call would look like this:
    final result = await getMaterialInfo(
      GetMaterialInfoParams(barcode: event.barcode),
    );

    result.fold(
      (failure) {
        debugPrint("ScanBloc: Error getting material info: ${failure.message}");
        emit(
          ScanErrorState(message: failure.message, previousState: currentState),
        );
      },
      (materialInfo) {
        debugPrint("ScanBloc: Successfully loaded material info");
        emit(
          MaterialInfoLoaded(
            isCameraActive: isCameraActive,
            isTorchEnabled: isTorchEnabled,
            controller: scannerController,
            scannedItems: scannedItems,
            materialInfo: materialInfo,
            currentBarcode: event.barcode,
          ),
        );
      },
    );
  }

  Future<void> _onSaveScannedData(
    SaveScannedData event,
    Emitter<ScanState> emit,
  ) async {
    debugPrint("ScanBloc: Saving scanned data: ${event.barcode}");

    final currentState = state;
    if (currentState is MaterialInfoLoaded) {
      // Create a new model
      emit(
        SavingDataState(
          isCameraActive: currentState.isCameraActive,
          isTorchEnabled: currentState.isTorchEnabled,
          controller: currentState.controller,
          scannedItems: currentState.scannedItems,
          materialInfo: currentState.materialInfo,
          currentBarcode: currentState.currentBarcode,
        ),
      );

      final scanRecord = ScanRecordModel.create(
        code: event.barcode,
        status: 'Pending',
        quantity: event.quantity,
        userId: event.userId,
        materialInfo: event.materialInfo,
      );

      final result = await saveScanRecord(
        SaveScanRecordParams(record: scanRecord),
      );

      result.fold(
        (failure) {
          debugPrint("ScanBloc: Error saving scan record: ${failure.message}");
          emit(
            ScanErrorState(
              message: failure.message,
              previousState: currentState,
            ),
          );
        },
        (savedRecord) {
          debugPrint("ScanBloc: Successfully saved scan record");
          emit(
            DataSavedState(
              savedRecord: savedRecord,
              scannedItems: currentState.scannedItems,
            ),
          );

          // Automatically send to processing after saving
          add(SendToProcessingEvent(currentUser.userId));
        },
      );
    }
  }

  Future<void> _onSendToProcessing(
    SendToProcessingEvent event,
    Emitter<ScanState> emit,
  ) async {
    debugPrint("ScanBloc: Sending to processing for user: ${event.userId}");

    final currentState = state;

    if (currentState is DataSavedState) {
      final List<ScanRecordEntity> records = [currentState.savedRecord];

      emit(SendingToProcessingState(records: records));

      final result = await sendToProcessing(
        SendToProcessingParams(records: records),
      );

      result.fold(
        (failure) {
          debugPrint(
            "ScanBloc: Error sending to processing: ${failure.message}",
          );
          emit(
            ScanErrorState(
              message: failure.message,
              previousState: currentState,
            ),
          );
        },
        (success) {
          debugPrint("ScanBloc: Processing complete");
          emit(const ProcessingCompleteState());

          // Reset to scanning state after processing
          add(StartNewScan());
        },
      );
    }
  }

  void _onStartNewScan(StartNewScan event, Emitter<ScanState> emit) {
    debugPrint("ScanBloc: Starting new scan");
    try {
      // Luôn dọn dẹp controller cũ trước
      if (scannerController != null) {
        try {
          scannerController!.stop();
          scannerController!.dispose();
        } catch (e) {
          debugPrint("Error disposing old controller: $e");
        }
        scannerController = null;
      }

      // Tạo controller mới
      scannerController = MobileScannerController();

      emit(
        ScanningState(
          isCameraActive: true,
          isTorchEnabled: false,
          controller: scannerController,
          scannedItems: [],
        ),
      );
    } catch (e) {
      debugPrint("Error starting new scan: $e");
      emit(
        ScanErrorState(
          message: "Không thể khởi động scanner: $e",
          previousState: state,
        ),
      );
    }
  }

  Future<void> _onHardwareScanButtonPressed(
    HardwareScanButtonPressed event,
    Emitter<ScanState> emit,
  ) async {
    debugPrint("ScanBloc: Hardware scan button pressed: ${event.scannedData}");

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

  Future<void> _onConfirmDeduction(
  ConfirmDeductionEvent event,
  Emitter<ScanState> emit,
) async {
  try {
    // Hiển thị trạng thái đang xử lý
    emit(SavingDataState(
      isCameraActive: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).isCameraActive : false,
      isTorchEnabled: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).isTorchEnabled : false,
      controller: scannerController,
      scannedItems: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).scannedItems : [],
      materialInfo: event.materialInfo,
      currentBarcode: event.barcode,
    ));
    
    // Gọi API để lưu dữ liệu khấu trừ
    final result = await remoteDataSource.saveQualityInspection(
      event.barcode,
      event.userId,
      event.deduction
    );
    
    if (result) {
      // Cập nhật processing service nếu thành công
      di.sl<ProcessingDataService>().addItem(
        event.materialInfo,
        event.barcode,
        event.quantity,
        event.deduction,
      );
      
      // Tạo record với số lượng đã trừ
      final remainingQuantity = (int.tryParse(event.quantity) ?? 0 - event.deduction).toString();
      
      final updatedMaterialInfo = Map<String, String>.from(event.materialInfo);
      updatedMaterialInfo['Quantity'] = remainingQuantity;
      
      final scanRecord = ScanRecordModel.create(
        code: event.barcode,
        status: 'Processed',
        quantity: remainingQuantity,
        userId: event.userId,
        materialInfo: updatedMaterialInfo,
      );
      
      // Lưu record vào local storage
      final saveResult = await saveScanRecord(SaveScanRecordParams(record: scanRecord));
      
      saveResult.fold(
        (failure) => emit(ScanErrorState(
          message: 'Failed to save record: ${failure.message}',
          previousState: state,
        )),
        (savedRecord) {
          List<List<String>> scannedItems = [];
          if (state is MaterialInfoLoaded) {
            scannedItems = (state as MaterialInfoLoaded).scannedItems;
          }
          
          emit(DataSavedState(
            savedRecord: savedRecord,
            scannedItems: scannedItems,
          ));
        },
      );
    } else {
      emit(ScanErrorState(
        message: 'Failed to process deduction',
        previousState: state,
      ));
    }
  } catch (e) {
    emit(ScanErrorState(
      message: 'Error processing deduction: $e',
      previousState: state,
    ));
  }
}
}
