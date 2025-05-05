import 'dart:async';
import 'dart:convert';
import 'package:architecture_scan_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/get_translate_key.dart';
import '../../domain/usecases/get_material_info.dart';
import '../../domain/usecases/save_scan_record.dart';
import '../../domain/usecases/send_to_processing.dart';
import '../../data/models/scan_record_model.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../../data/datasources/scan_service_impl.dart';
import 'bloc_helper.dart';
import 'scan_event.dart';
import 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final GetMaterialInfo getMaterialInfo;
  final SaveScanRecord saveScanRecord;
  final SendToProcessing sendToProcessing;
  final UserEntity currentUser;
  final ScanRemoteDataSource remoteDataSource;

  bool _isLoadingReasons = false;

  List<String> _cachedReasons = [];

  ScanBloc({
    required this.remoteDataSource,
    required this.getMaterialInfo,
    required this.saveScanRecord,
    required this.sendToProcessing,
    required this.currentUser,
  }) : super(ScanInitial()) {
    on<BarcodeDetected>(_onBarcodeDetectedAsync);
    on<GetMaterialInfoEvent>(_onGetMaterialInfoAsync);
    on<SaveScannedData>(_onSaveScannedDataAsync);
    on<HardwareScanButtonPressed>(_onHardwareScanButtonPressedAsync);
    on<ConfirmDeductionEvent>(_onConfirmDeductionAsync);
    on<InitializeScanService>(_onInitializeScanServiceAsync);
    on<ClearScannedItems>(_onClearScannedItemsAsync);
    on<ShowClearConfirmationEvent>(_onShowClearConfirmationAsync);
    on<ConfirmClearScannedItems>(_onConfirmClearScannedItemsAsync);
    on<CancelClearScannedItems>(_onCancelClearScannedItemsAsync);
    on<LoadReasonsEvent>(_onLoadReasonsAsync);
    on<ReasonsSelectedEvent>(_onReasonsSelected);
  }

  
  
  Future<void> _onCancelClearScannedItemsAsync(CancelClearScannedItems event, Emitter<ScanState> emit) async {
    if (state is ShowClearConfirmationState) {
      emit((state as ShowClearConfirmationState).previousState);
    }
  }

  Future<void> _onConfirmClearScannedItemsAsync(ConfirmClearScannedItems event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Confirming clear scanned items");
    
    emit(ScanningState(
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

  Future<void> _onInitializeScanServiceAsync(InitializeScanService event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Initializing scan service");
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

  Future<void> _onGetMaterialInfoAsync(GetMaterialInfoEvent event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Getting material info for: ${event.barcode}");

    final currentState = state;
    List<List<String>> scannedItems = [];

    if (currentState is ScanningState) {
      scannedItems = List.from(currentState.scannedItems);

    } else if (currentState is MaterialInfoLoaded) {
      scannedItems = List.from(currentState.scannedItems);
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
            scannedItems: scannedItems,
            materialInfo: materialInfo,
            currentBarcode: event.barcode,
          ),
        );
      },
    );
  }

  Future<void> _onSaveScannedDataAsync(SaveScannedData event, Emitter<ScanState> emit) async {
    debugPrint("ScanBloc: Saving scanned data: ${event.barcode}");

    final currentState = state;
    if (currentState is MaterialInfoLoaded) {
      emit(
        SavingDataState(
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
        qcQtyIn: qcQtyIn,
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
          emit(MaterialInfoLoaded(
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


  Future<void> _onConfirmDeductionAsync(ConfirmDeductionEvent event, Emitter<ScanState> emit) async {
    try {
      List<String> selectedReasons = [];

      if (state is ReasonsLoadedState) {
        selectedReasons = (state as ReasonsLoadedState).selectedReasons;
      } else if (event.reasons != null) {
        selectedReasons = event.reasons!;
      }
      
      if (!ScanBlocHelper.validateDeduction(event.deduction, selectedReasons, event.isQC2User)) {
        emit(ScanErrorState(
          message: event.isQC2User ? StringKey.eitherDeductionOrReasonsMessage : StringKey.reasonsRequiredMessage,
          previousState: state,
        ));
        return;
      }

      emit(SavingDataState(
        scannedItems: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).scannedItems : [],
        materialInfo: event.materialInfo,
        currentBarcode: event.barcode,
      ));

      bool result;
      if (event.isQC2User) {
        result = await remoteDataSource.saveQC2DeductionRemoteDataAsync(
          event.barcode,
          event.userId,
          event.deduction,
          event.optionFunction!,
          selectedReasons,
        );
      } else {
        result = await remoteDataSource.saveQualityInspectionRemoteDataAsync(
          event.barcode,
          event.userId,
          event.deduction,
          selectedReasons,
        );
      }

      if (result) {
      emit(DataSavedState(
        savedRecord: ScanRecordModel.create(
          code: event.barcode,
          status: 'Saved',
          quantity: event.quantity,
          userId: event.userId,
          materialInfo: event.materialInfo,
          qcQtyOut: event.qcQtyOut,
          qcQtyIn: event.qcQtyIn,
        ),
        scannedItems: state is MaterialInfoLoaded ? (state as MaterialInfoLoaded).scannedItems : [],
      ));
    } else {
      emit(ScanErrorState(
        message: StringKey.saveFailedMessage,
        previousState: state,
      ));
}
    } catch (e) {
      emit(
        ScanErrorState(
          message: StringKey.eitherDeductionOrReasonsMessage,
          previousState: state,
        ),
      );
    }
  }

  Future<void> _onLoadReasonsAsync(LoadReasonsEvent event, Emitter<ScanState> emit) async {
    if (_isLoadingReasons || (_cachedReasons.isNotEmpty && state is! ReasonsLoadingState)) {
      if (_cachedReasons.isNotEmpty) {
        emit(ReasonsLoadedState(
          baseState: state,
          availableReasons: _cachedReasons,
        ));
      }
      return;
    }

    _isLoadingReasons = true;
    emit(ReasonsLoadingState(baseState: state));

    try {
      final reasons = await remoteDataSource.getDeductionReasonsAsync();
      _cachedReasons = reasons;
      
      emit(ReasonsLoadedState(
        baseState: state is ReasonsLoadingState
            ? (state as ReasonsLoadingState).baseState
            : state,
        availableReasons: reasons,
      ));
    } catch (e) {
      emit(ScanErrorState(
        message: 'Failed to load reasons: $e',
        previousState: state is ReasonsLoadingState
            ? (state as ReasonsLoadingState).baseState
            : state,
      ));
    } finally {
      _isLoadingReasons = false;
    }
  }

  void _onReasonsSelected(ReasonsSelectedEvent event, Emitter<ScanState> emit) {
    if (state is ReasonsLoadedState) {
      final currentState = state as ReasonsLoadedState;
      emit(currentState.copyWith(selectedReasons: event.selectedReasons));
    }
  }

  List<String> getAvailableReasons() {
    if (_cachedReasons.isNotEmpty) {
      return _cachedReasons;
    }
    
    add(LoadReasonsEvent());
    return [];
  }

  void processBarcodeData(String barcode) {
    add(BarcodeDetected(barcode));
  }
}
