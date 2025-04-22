import 'dart:async';
import 'dart:convert';
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
  bool _isCameraInitializing = false;
  bool _isCameraDisposing = false;

  MobileScannerController? scannerController;
  
  bool _isCameraActive = false;
  bool _isTorchEnabled = false;

  ScanBloc({
    required this.remoteDataSource,
    required this.getMaterialInfo,
    required this.saveScanRecord,
    required this.sendToProcessing,
    required this.currentUser,
  }) : super(ScanInitial()) {
    on<InitializeScanner>(_onInitializeScannerAsync);
    on<BarcodeDetected>(_onBarcodeDetectedAsync);
    on<ToggleCamera>(_onToggleCameraAsync);
    on<ToggleTorch>(_onToggleTorchAsync);
    on<SwitchCamera>(_onSwitchCameraAsync);
    on<GetMaterialInfoEvent>(_onGetMaterialInfoAsync);
    on<SaveScannedData>(_onSaveScannedDataAsync);
    on<SendToProcessingEvent>(_onSendToProcessingAsync);
    on<HardwareScanButtonPressed>(_onHardwareScanButtonPressedAsync);
    on<ConfirmDeductionEvent>(_onConfirmDeductionAsync);
    on<InitializeScanService>(_onInitializeScanServiceAsync);
    on<ClearScannedItems>(_onClearScannedItemsAsync);
    on<ShowClearConfirmationEvent>(_onShowClearConfirmationAsync);
    on<ConfirmClearScannedItems>(_onConfirmClearScannedItemsAsync);
    on<CancelClearScannedItems>(_onCancelClearScannedItemsAsync);
    
    ScanService.initializeScannerListenerAsync(_handleHardwareScan);
  }

  
  
  Future<void> _onCancelClearScannedItemsAsync(CancelClearScannedItems event, Emitter<ScanState> emit) async {
    if (state is ShowClearConfirmationState) {
      emit((state as ShowClearConfirmationState).previousState);
    }
  }

  Future<void> _onConfirmClearScannedItemsAsync(ConfirmClearScannedItems event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Confirming clear scanned items");
    
    emit(ScanningState(
      isCameraActive: _isCameraActive,
      isTorchEnabled: false,
      controller: scannerController,
      scannedItems: [],
    ));
    
    ScanService.clearScannedBarcodesAsync();
  }

  Future<void> _onShowClearConfirmationAsync(
    ShowClearConfirmationEvent event,
    Emitter<ScanState> emit
  ) async {
    emit(ShowClearConfirmationState(previousState: state));
  }

  Future<void> _onClearScannedItemsAsync(ClearScannedItems event, Emitter<ScanState> emit) async {
    add(ShowClearConfirmationEvent());
  }

  Future<void> _handleHardwareScan(String scannedData) async {
    if (scannedData.isNotEmpty) {
      add(HardwareScanButtonPressed(scannedData));
    }
  }

  Future<void> _onInitializeScanServiceAsync(InitializeScanService event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Initializing scan service");
  }

  Future<void> _onInitializeScannerAsync(InitializeScanner event, Emitter<ScanState> emit) async {
  if (_isCameraInitializing) {
    debugPrint("ScanBloc: Camera đang được khởi tạo, bỏ qua yêu cầu mới");
    return;
  }

  _isCameraInitializing = true;
  emit(ScanInitializingState());

  await _cleanupControllerAsync();

  try {
    scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      facing: CameraFacing.back,
      torchEnabled: _isTorchEnabled
    );

    bool started = await _startCameraWithTimeout();
    if (!started) {
      throw Exception("Camera initialization timed out");
    }

    _isCameraActive = true;
    
    emit(ScanningState(
      isCameraActive: _isCameraActive,
      isTorchEnabled: _isTorchEnabled,
      controller: scannerController,
      scannedItems: [],
    ));

  } catch (e) {
    debugPrint("ScanBloc: Lỗi khởi tạo camera: $e");

    await _cleanupControllerAsync();

    emit(ScanErrorState(
      message: "$e",
      previousState: state,
    ));

  } finally {
    _isCameraInitializing = false;

  }
}

  Future<bool> _startCameraWithTimeout() async {
    Completer<bool> completer = Completer();
    
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    
    scannerController!.start().then((_) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }).catchError((error) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    
    return completer.future;
  }

  Future<void> _cleanupControllerAsync() async {
    if (scannerController == null || _isCameraDisposing) return;
    
    _isCameraDisposing = true;
    
    try {
      if (_isCameraActive) {
        await scannerController!.stop();
      }
      
      await scannerController!.dispose();

    } catch (e) {
      debugPrint("ScanBloc: Lỗi khi dọn dẹp camera: $e");
      
    } finally {
      scannerController = null;
      _isCameraActive = false;
      _isCameraDisposing = false;
    }
  }

  Future<void> _onBarcodeDetectedAsync(BarcodeDetected event, Emitter<ScanState> emit) async {
    if (state is ScanProcessingState) return;

    emit(ScanProcessingState(barcode: event.barcode));

    try {
      final result = await getMaterialInfo(
        GetMaterialInfoParams(barcode: event.barcode),
      );

      await result.fold(
        (failure) async {
          emit(ScanErrorState(message: failure.message, previousState: state));
        },
        (materialInfo) async {
          try {
            final materialInfoMap = Map<String, String>.from(
              materialInfo.map(
                (key, value) => MapEntry(key, value.toString()),
              ),
            );

            final processedItems = await compute(_processScannedItemsAsync, {
              'barcode': event.barcode,
              'materialInfoJson': jsonEncode(materialInfoMap),
              'existingItemsJson': jsonEncode(
                _efficientlyGetScannedItems(state),
              ),
            });

            if (!emit.isDone) {
              emit(
                MaterialInfoLoaded(
                  isCameraActive:
                      state is ScanningState
                          ? (state as ScanningState).isCameraActive
                          : true,
                  isTorchEnabled:
                      state is ScanningState
                          ? (state as ScanningState).isTorchEnabled
                          : false,
                  controller: scannerController,
                  scannedItems: processedItems,
                  materialInfo: materialInfoMap,
                  currentBarcode: event.barcode,
                ),
              );
            }
          } catch (e) {
            if (!emit.isDone) {
              emit(
                ScanErrorState(
                  message: "Processing error: $e",
                  previousState: state,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(
          ScanErrorState(
            message: "Error processing scan: $e",
            previousState: state,
          ),
        );
      }
    }
  }

  static Future<List<List<String>>> _processScannedItemsAsync(Map<String, dynamic> params) async {
    final String barcode = params['barcode'];
    final String materialInfoJson = params['materialInfoJson'];
    final List<List<String>> existingItems =
        (jsonDecode(params['existingItemsJson']) as List)
            .map((item) => (item as List).map((e) => e.toString()).toList())
            .toList();

    final Map<String, dynamic> materialInfo = jsonDecode(materialInfoJson);

    final isAlreadyScanned = existingItems.any(
      (item) => item.isNotEmpty && item[0] == barcode,
    );

    final List<List<String>> result = List.from(existingItems);

    if (!isAlreadyScanned) {
      result.add([
        barcode,
        'Scanned',
        materialInfo['Quantity']?.toString() ?? '0',
      ]);
    }

    return result;
  }

  List<List<String>> _efficientlyGetScannedItems(ScanState state) {
    if (state is ScanningState) {
      return state.scannedItems;
    } else if (state is MaterialInfoLoaded) {
      return state.scannedItems;
    }
    return [];
  }

  Future<void> _onToggleCameraAsync(ToggleCamera event, Emitter<ScanState> emit) async {
  if (event.isActive == _isCameraActive) return;
  
  if (_isCameraInitializing || _isCameraDisposing) {
      debugPrint("ScanBloc: Camera đang trong quá trình chuyển đổi, bỏ qua");
      return;
    }
    
    if (event.isActive) {
      add(InitializeScanner());

    } else {
      await _cleanupControllerAsync();
      
      if (state is ScanningState) {
        emit((state as ScanningState).copyWith(isCameraActive: false));

      } else if (state is MaterialInfoLoaded) {
        emit((state as MaterialInfoLoaded).copyWith(isCameraActive: false));

      }
    }
  }

  Future<void> _onToggleTorchAsync(ToggleTorch event, Emitter<ScanState> emit) async {
    if (scannerController == null || !_isCameraActive) return;
    
    try {
      await scannerController!.toggleTorch();
      _isTorchEnabled = !_isTorchEnabled;
      
      if (state is ScanningState) {
        emit((state as ScanningState).copyWith(isTorchEnabled: _isTorchEnabled));

      } else if (state is MaterialInfoLoaded) {
        emit((state as MaterialInfoLoaded).copyWith(isTorchEnabled: _isTorchEnabled));

      }
    } catch (e) {
      debugPrint("ScanBloc: Lỗi khi bật/tắt đèn flash: $e");
    }
  }

  Future<void> _onSwitchCameraAsync(SwitchCamera event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Switch camera");
    
    if (scannerController == null || !_isCameraActive) {
      debugPrint("ScanBloc: Cannot switch camera, camera not active");
      return;
    }
    
    try {
      await scannerController!.switchCamera();

    } catch (e) {
      debugPrint("ScanBloc: Error switching camera: $e");
    }
  }

  Future<void> _onGetMaterialInfoAsync(
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

  Future<void> _onSaveScannedDataAsync(
    SaveScannedData event,
    Emitter<ScanState> emit,
  ) async {
    debugPrint("ScanBloc: Saving scanned data: ${event.barcode}");

    final currentState = state;
    if (currentState is MaterialInfoLoaded) {
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

      final double qcQtyOut = double.tryParse(event.materialInfo['Deduction_QC2'] ?? '0') ?? 0;
      final double qcQtyIn = double.tryParse(event.materialInfo['Deduction_QC1'] ?? '0') ?? 0;

      final scanRecord = ScanRecordModel.create(
        code: event.barcode,
        status: 'Pending',
        quantity: event.quantity,
        userId: event.userId,
        materialInfo: event.materialInfo,
        qcQtyOut: qcQtyOut,
        qcQtyIn: qcQtyIn
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

          add(SendToProcessingEvent(currentUser.userId));
        },
      );
    }
  }

  Future<void> _onSendToProcessingAsync(
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

          add(InitializeScanner());
        },
      );
    }
  }

  Future<void> _onHardwareScanButtonPressedAsync(
    HardwareScanButtonPressed event,
    Emitter<ScanState> emit
  ) async {
    if (event.scannedData.isEmpty) return;
    
    emit(ScanProcessingState(barcode: event.scannedData));
    
    try {
      final result = await getMaterialInfo(
        GetMaterialInfoParams(barcode: event.scannedData),
      );
      
      await result.fold(
        (failure) async {
          emit(ScanErrorState(
            message: failure.message,
            previousState: state,
          ));
        },
        (materialInfo) async {
          bool currentCameraState = false;

          if (state is ScanningState) {
            currentCameraState = (state as ScanningState).isCameraActive;

          } else if (state is MaterialInfoLoaded) {
            currentCameraState = (state as MaterialInfoLoaded).isCameraActive;
          }
          
          emit(MaterialInfoLoaded(
            isCameraActive: currentCameraState,
            isTorchEnabled: false,
            controller: scannerController,
            scannedItems: _efficientlyGetScannedItems(state),
            materialInfo: materialInfo,
            currentBarcode: event.scannedData,
          ));
        }
      );
    } catch (e) {
      emit(ScanErrorState(
        message: "Error processing scan: $e",
        previousState: state,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _cleanupControllerAsync();
    
    ScanService.disposeScannerListenerAsync();
    
    return super.close();
  }


  Future<void> _onConfirmDeductionAsync(
    ConfirmDeductionEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      bool currentCameraActive = _isCameraActive;
      bool currentTorchEnabled = _isTorchEnabled;

      emit(
        SavingDataState(
          isCameraActive: currentCameraActive,
          isTorchEnabled: currentTorchEnabled,
          controller: scannerController,
          scannedItems: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).scannedItems : [],
          materialInfo: event.materialInfo,
          currentBarcode: event.barcode,
        ),
      );

      bool result;
      if (event.isQC2User) {
        result = await remoteDataSource.saveQC2DeductionRemoteDataAsync(
          event.barcode,
          event.userId,
          event.deduction,
          event.optionFunction,
        );
      } else {
        result = await remoteDataSource.saveQualityInspectionRemoteDataAsync(
          event.barcode,
          event.userId,
          event.deduction,
        );
      }

      if (result) {
        final remainingQuantity =
            (int.tryParse(event.quantity) ?? 0 - event.deduction).toString();

        final updatedMaterialInfo = Map<String, String>.from(event.materialInfo);
        updatedMaterialInfo['Quantity'] = remainingQuantity;

        final scanRecord = ScanRecordModel.create(
          code: event.barcode,
          status: 'Processed',
          quantity: remainingQuantity,
          userId: event.userId,
          materialInfo: updatedMaterialInfo,
          qcQtyOut: event.qcQtyOut,
          qcQtyIn: event.qcQtyIn,
        );

        final saveResult = await saveScanRecord(
          SaveScanRecordParams(record: scanRecord),
        );

        saveResult.fold(
          (failure) => emit(
            ScanErrorState(
              message: 'Failed to save record: ${failure.message}',
              previousState: state,
              isCameraActive: currentCameraActive,
              isTorchEnabled: currentTorchEnabled,
              controller: scannerController,
            ),
          ),
          (savedRecord) {
            List<List<String>> scannedItems = [];
            if (state is MaterialInfoLoaded) {
              scannedItems = (state as MaterialInfoLoaded).scannedItems;
            }

            emit(
              DataSavedState(
                savedRecord: savedRecord,
                scannedItems: scannedItems,
                isCameraActive: currentCameraActive,
                isTorchEnabled: currentTorchEnabled,
                controller: scannerController,
              ),
            );
          },
        );
      }
    } catch (e) {
      bool currentCameraActive = _isCameraActive;
      bool currentTorchEnabled = _isTorchEnabled;
      
      emit(
        ScanErrorState(
          message: '$e',
          previousState: state,
          isCameraActive: currentCameraActive,
          isTorchEnabled: currentTorchEnabled,
          controller: scannerController,
        ),
      );
    }
  }
}
