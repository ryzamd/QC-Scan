import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanService {
  static const EventChannel _eventChannel = EventChannel('com.example.architecture_scan_app/scanner');
  static const MethodChannel _methodChannel = MethodChannel('com.example.architecture_scan_app');
  
  static ScanService? _instance;
  static ScanService get instance => _instance ??= ScanService._internal();
  
  ScanService._internal();
  
  Function(String)? onBarcodeScanned;

  static const int MAX_HISTORY_SIZE = 20;
  final List<String> scannedBarcodes = [];
  
  StreamSubscription? _subscription;
  Timer? _debounceTimer;
  bool _isInitialized = false;

  static Future<void> initializeScannerListenerAsync(Function(String) onScanned) async {
    await instance._initializeListenerAsync(onScanned);
  }
  
  Future<void> _initializeListenerAsync(Function(String) onScanned) async {
    if (_isInitialized) {
      await _disposeListenerAsync();
    }
    
    _isInitialized = true;
    onBarcodeScanned = onScanned;
    
    debugPrint("Hardware scanner event channel initializing");
    
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic scanData) {
        if (_debounceTimer?.isActive ?? false) return;
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
        
        if (scanData != null && scanData.toString().isNotEmpty) {
          _processScanDataAsync(scanData.toString());
        }
      },
      onError: (dynamic error) {
        debugPrint("Hardware scanner error: $error");
      }
    );
    
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "scannerKeyPressed") {
        String scannedData = call.arguments.toString();
        
        if (_debounceTimer?.isActive ?? false) return null;
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
        
        _processScanDataAsync(scannedData);
      }
      return null;
    });
  }
  
  Future<void> _processScanDataAsync(String data) async {
    if (scannedBarcodes.length >= MAX_HISTORY_SIZE) {
      scannedBarcodes.removeAt(0);
    }
    scannedBarcodes.add(data);
    
    onBarcodeScanned?.call(data);
  }
  
  static Future<void> disposeScannerListenerAsync() async {
    await instance._disposeListenerAsync();
  }
  
  Future<void> _disposeListenerAsync() async {
    await _subscription?.cancel();
    _subscription = null;
    onBarcodeScanned = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isInitialized = false;
  }

  static Future<bool> isScannerButtonPressedAsync(KeyEvent event) async {
    const scannerKeyCodes = [120, 121, 122, 293, 294, 73014444552];
    return scannerKeyCodes.contains(event.logicalKey.keyId);
  }
  
  static Future<void> clearScannedBarcodesAsync() async {
    instance.scannedBarcodes.clear();
    debugPrint("QR DEBUG: Scanned barcodes history cleared");
  }
}