// lib/features/scan/presentation/bloc/scan_bloc.dart
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
  
  // Track camera state internally
  bool _isCameraActive = false;
  bool _isTorchEnabled = false;

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
    on<HardwareScanButtonPressed>(_onHardwareScanButtonPressed);
    on<ConfirmDeductionEvent>(_onConfirmDeduction);
    on<InitializeScanService>(_onInitializeScanService);
    on<ClearScannedItems>(_onClearScannedItems);
    on<ShowClearConfirmationEvent>(_onShowClearConfirmation);
    on<ConfirmClearScannedItems>(_onConfirmClearScannedItems);
    on<CancelClearScannedItems>(_onCancelClearScannedItems);
    
    // Initialize ScanService for hardware scanner
    ScanService.initializeScannerListener(_handleHardwareScan);
  }

  
  
  void _onCancelClearScannedItems(
    CancelClearScannedItems event,
    Emitter<ScanState> emit
  ) {
    if (state is ShowClearConfirmationState) {
      emit((state as ShowClearConfirmationState).previousState);
    }
  }

  void _onConfirmClearScannedItems(
    ConfirmClearScannedItems event,
    Emitter<ScanState> emit
  ) {
    debugPrint("ScanBloc: Confirming clear scanned items");
    

    emit(ScanningState(
      isCameraActive: _isCameraActive,
      isTorchEnabled: false,
      controller: scannerController,
      scannedItems: [],
    ));
    
    ScanService.clearScannedBarcodes();
  }

  void _onShowClearConfirmation(
    ShowClearConfirmationEvent event,
    Emitter<ScanState> emit
  ) {
    emit(ShowClearConfirmationState(previousState: state));
  }

  void _onClearScannedItems(ClearScannedItems event, Emitter<ScanState> emit) {
    add(ShowClearConfirmationEvent());
  }

  void _handleHardwareScan(String scannedData) {
    if (scannedData.isNotEmpty) {
      add(HardwareScanButtonPressed(scannedData));
    }
  }

  // New method to initialize scan service
  void _onInitializeScanService(InitializeScanService event, Emitter<ScanState> emit) {
    debugPrint("ScanBloc: Initializing scan service");
  }

  Future<void> _onInitializeScanner(InitializeScanner event, Emitter<ScanState> emit) async {
  // Nếu đã đang khởi tạo camera, tránh khởi tạo lại
  if (_isCameraInitializing) {
    debugPrint("ScanBloc: Camera đang được khởi tạo, bỏ qua yêu cầu mới");
    return;
  }

  // Đánh dấu đang khởi tạo
  _isCameraInitializing = true;
  emit(ScanInitializingState());

  // Đảm bảo controller cũ đã được giải phóng
  await _cleanupController();

  try {
    // Tạo controller mới
    scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: _isTorchEnabled
    );

    // Khởi động camera với timeout
    bool started = await _startCameraWithTimeout();
    if (!started) {
      throw Exception("Khởi tạo camera quá thời gian chờ");
    }

    // Cập nhật trạng thái
    _isCameraActive = true;
    
    emit(ScanningState(
      isCameraActive: _isCameraActive,
      isTorchEnabled: _isTorchEnabled,
      controller: scannerController,
      scannedItems: [],
    ));
  } catch (e) {
    debugPrint("ScanBloc: Lỗi khởi tạo camera: $e");
    await _cleanupController();
    emit(ScanErrorState(
      message: "Không thể khởi tạo camera: $e",
      previousState: state,
    ));
  } finally {
    _isCameraInitializing = false;
  }
}

// Thêm hàm khởi động camera với timeout
Future<bool> _startCameraWithTimeout() async {
  Completer<bool> completer = Completer();
  
  // Đặt timeout 5 giây
  Timer(const Duration(seconds: 5), () {
    if (!completer.isCompleted) {
      completer.complete(false);
    }
  });
  
  // Bắt đầu camera
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

  Future<void> _cleanupController() async {
    // Nếu không có controller hoặc đang dọn dẹp, bỏ qua
    if (scannerController == null || _isCameraDisposing) return;
    
    _isCameraDisposing = true;
    
    try {
      // Dừng camera trước
      if (_isCameraActive) {
        await scannerController!.stop();
      }
      
      // Giải phóng controller
      await scannerController!.dispose();
    } catch (e) {
      debugPrint("ScanBloc: Lỗi khi dọn dẹp camera: $e");
    } finally {
      scannerController = null;
      _isCameraActive = false;
      _isCameraDisposing = false;
    }
  }

  Future<void> _onBarcodeDetected(
    BarcodeDetected event,
    Emitter<ScanState> emit,
  ) async {
    if (state is ScanProcessingState) return;

    emit(ScanProcessingState(barcode: event.barcode));

    try {
      // Quan trọng: phải await result.fold hoàn toàn
      final result = await getMaterialInfo(
        GetMaterialInfoParams(barcode: event.barcode),
      );

      await result.fold(
        (failure) async {
          emit(ScanErrorState(message: failure.message, previousState: state));
        },
        (materialInfo) async {
          // Thêm async và await cho đúng
          try {
            // Đảm bảo materialInfo là Map<String, String> trước khi encode
            final materialInfoMap = Map<String, String>.from(
              materialInfo.map(
                (key, value) => MapEntry(key, value.toString()),
              ),
            );

            // Truyền dữ liệu đơn giản qua compute
            final processedItems = await compute(_processScannedItems, {
              'barcode': event.barcode,
              'materialInfoJson': jsonEncode(materialInfoMap),
              'existingItemsJson': jsonEncode(
                _efficientlyGetScannedItems(state),
              ),
            });

            // Kiểm tra xem emit có còn khả dụng không
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

  // Hàm xử lý chạy trong isolate
  static List<List<String>> _processScannedItems(Map<String, dynamic> params) {
    final String barcode = params['barcode'];
    final String materialInfoJson = params['materialInfoJson'];
    final List<List<String>> existingItems =
        (jsonDecode(params['existingItemsJson']) as List)
            .map((item) => (item as List).map((e) => e.toString()).toList())
            .toList();

    // Chuyển JSON thành Map
    final Map<String, dynamic> materialInfo = jsonDecode(materialInfoJson);

    // Kiểm tra nếu đã có
    final isAlreadyScanned = existingItems.any(
      (item) => item.isNotEmpty && item[0] == barcode,
    );

    // Tạo bản sao
    final List<List<String>> result = List.from(existingItems);

    // Thêm item mới nếu chưa có
    if (!isAlreadyScanned) {
      result.add([
        barcode,
        'Scanned',
        materialInfo['Quantity']?.toString() ?? '0',
      ]);
    }

    return result;
  }

  // Efficiently get scanned items without unnecessary allocations
  List<List<String>> _efficientlyGetScannedItems(ScanState state) {
    if (state is ScanningState) {
      return state.scannedItems;
    } else if (state is MaterialInfoLoaded) {
      return state.scannedItems;
    }
    return [];
  }

  Future<void> _onToggleCamera(ToggleCamera event, Emitter<ScanState> emit) async {
  // Nếu trạng thái không thay đổi, bỏ qua
  if (event.isActive == _isCameraActive) return;
  
  if (_isCameraInitializing || _isCameraDisposing) {
      debugPrint("ScanBloc: Camera đang trong quá trình chuyển đổi, bỏ qua");
      return;
    }
    
    if (event.isActive) {
      // Khởi tạo camera - chỉ gọi event, không emit
      add(InitializeScanner());
    } else {
      // Tắt camera và cập nhật state ngay
      await _cleanupController();
      
      // Cập nhật state dựa trên state hiện tại
      if (state is ScanningState) {
        emit((state as ScanningState).copyWith(isCameraActive: false));
      } else if (state is MaterialInfoLoaded) {
        emit((state as MaterialInfoLoaded).copyWith(isCameraActive: false));
      }
    }
  }

  Future<void> _onToggleTorch(ToggleTorch event, Emitter<ScanState> emit) async {
    // Nếu không có controller hoặc camera không hoạt động, bỏ qua
    if (scannerController == null || !_isCameraActive) return;
    
    try {
      // Bật/tắt đèn flash ngay lập tức
      await scannerController!.toggleTorch();
      _isTorchEnabled = !_isTorchEnabled;
      
      // Cập nhật state ngay
      if (state is ScanningState) {
        emit((state as ScanningState).copyWith(isTorchEnabled: _isTorchEnabled));
      } else if (state is MaterialInfoLoaded) {
        emit((state as MaterialInfoLoaded).copyWith(isTorchEnabled: _isTorchEnabled));
      }
    } catch (e) {
      debugPrint("ScanBloc: Lỗi khi bật/tắt đèn flash: $e");
    }
  }

  Future<void> _onSwitchCamera(SwitchCamera event, Emitter<ScanState> emit) async {
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

      final double qcQtyOut = double.tryParse(event.materialInfo['qc_qty_out'] ?? '0') ?? 0;

      final scanRecord = ScanRecordModel.create(
        code: event.barcode,
        status: 'Pending',
        quantity: event.quantity,
        userId: event.userId,
        materialInfo: event.materialInfo,
        qcQtyOut: qcQtyOut
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
          add(InitializeScanner());
        },
      );
    }
  }

  Future<void> _onHardwareScanButtonPressed(
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
        // Bảo toàn trạng thái camera hiện tại
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
    await _cleanupController();
    
    ScanService.disposeScannerListener();
    
    return super.close();
  }


  Future<void> _onConfirmDeduction(
    ConfirmDeductionEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
    emit(
      SavingDataState(
        isCameraActive: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).isCameraActive : false,
        isTorchEnabled: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).isTorchEnabled : false,
        controller: scannerController,
        scannedItems: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).scannedItems : [],
        materialInfo: event.materialInfo,
        currentBarcode: event.barcode,
      ),
    );

    bool result;
    if (event.isQC2User) {
      // Call the QC2-specific API
      result = await remoteDataSource.saveQC2Deduction(
        event.barcode,
        event.userId,
        event.deduction,
      );
    } else {
      // Call the existing QC1 API
      result = await remoteDataSource.saveQualityInspection(
        event.barcode,
        event.userId,
        event.deduction,
      );
    }

      if (result) {
        final remainingQuantity =
            (int.tryParse(event.quantity) ?? 0 - event.deduction).toString();

        final updatedMaterialInfo = Map<String, String>.from(
          event.materialInfo,
        );
        updatedMaterialInfo['Quantity'] = remainingQuantity;

        final scanRecord = ScanRecordModel.create(
          code: event.barcode,
          status: 'Processed',
          quantity: remainingQuantity,
          userId: event.userId,
          materialInfo: updatedMaterialInfo,
          qcQtyOut: event.qcQtyOut,
        );

        // Lưu record vào local storage
        final saveResult = await saveScanRecord(
          SaveScanRecordParams(record: scanRecord),
        );

        saveResult.fold(
          (failure) => emit(
            ScanErrorState(
              message: 'Failed to save record: ${failure.message}',
              previousState: state,
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
              ),
            );
          },
        );
      } else {
        emit(
          ScanErrorState(
            message: 'Failed to process deduction',
            previousState: state,
          ),
        );
      }
    } catch (e) {
      emit(
        ScanErrorState(
          message: 'Error processing deduction: $e',
          previousState: state,
        ),
      );
    }
  }
}
