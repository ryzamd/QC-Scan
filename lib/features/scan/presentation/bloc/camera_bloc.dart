import 'package:bloc/bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  MobileScannerController? scannerController;
  bool _isCameraActive = false;
  bool _isTorchEnabled = false;
  bool _isCameraInitializing = false;
  bool _isCameraDisposing = false;
  
  final void Function(String)? onDetect;

  CameraBloc({this.onDetect}) : super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCameraAsync);
    on<ToggleCamera>(_onToggleCameraAsync);
    on<ToggleTorch>(_onToggleTorchAsync);
    on<SwitchCamera>(_onSwitchCameraAsync);
    on<CleanupCamera>(_onCleanupCameraAsync);
  }

  @override
  Future<void> close() async {
    await _cleanupResourcesAsync();
    return super.close();
  }

  Future<void> _cleanupResourcesAsync() async {
    if (_isCameraDisposing) return;
    _isCameraDisposing = true;

    scannerController?.stop();
    await scannerController?.dispose();
    scannerController = null;
    _isCameraDisposing = false;
  }

  void _onInitializeCameraAsync(InitializeCamera event, Emitter<CameraState> emit) {
    if (_isCameraInitializing || scannerController != null) return;
    _isCameraInitializing = true;

    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: _isTorchEnabled,
    );

    emit(CameraInitializing());

    emit(CameraReady(
      isActive: false,
      isTorchEnabled: _isTorchEnabled,
    ));
    
    _isCameraInitializing = false;
  }

  void _onToggleCameraAsync(ToggleCamera event, Emitter<CameraState> emit) {
    _isCameraActive = event.isActive;
    if (_isCameraActive) {
      scannerController?.start();
    } else {
      scannerController?.stop();
    }
    emit(CameraReady(
      isActive: _isCameraActive,
      isTorchEnabled: _isTorchEnabled,
    ));
  }

  void _onToggleTorchAsync(ToggleTorch event, Emitter<CameraState> emit) {
    if (_isCameraActive == false) return;

    _isTorchEnabled = event.isEnabled;
    if (scannerController != null) {
      scannerController?.toggleTorch();
    }
    emit(CameraReady(
      isActive: _isCameraActive,
      isTorchEnabled: _isTorchEnabled,
    ));
  }

  void _onSwitchCameraAsync(SwitchCamera event, Emitter<CameraState> emit) {
    if (_isCameraActive == false) return;

    if (scannerController != null) {
      scannerController?.switchCamera();
    }
    emit(CameraReady(
      isActive: _isCameraActive,
      isTorchEnabled: _isTorchEnabled,
    ));
  }

  void _onCleanupCameraAsync(CleanupCamera event, Emitter<CameraState> emit) async {
    await _cleanupResourcesAsync();
    emit(CameraInitial());
  }
  
  void handleDetection(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        onDetect?.call(barcode.rawValue!);
      }
    }
  }
}