// Fixed implementation for ScanService class
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for handling hardware scanner integration
class ScanService {
  static const EventChannel _eventChannel = EventChannel('com.example.architecture_scan_app/scanner');
  static const MethodChannel _methodChannel = MethodChannel('com.example.architecture_scan_app');
  
  // Singleton instance
  static ScanService? _instance;
  static ScanService get instance => _instance ??= ScanService._internal();
  
  // Private constructor
  ScanService._internal();
  
  // Callback for scan events
  Function(String)? onBarcodeScanned;

  final List<String> scannedBarcodes = []; // Store scanned barcodes
  
  // Stream subscription for event channel
  StreamSubscription? _subscription;
  
  // Debounce timer to avoid duplicate scans
  Timer? _debounceTimer;
  
  // Flag to track if the service is initialized
  bool _isInitialized = false;

  // Initialize scanner listener - use a factory for the singleton
  static void initializeScannerListener(Function(String) onScanned) {
    instance._initializeListener(onScanned);
  }
  
  // Internal method to initialize the listener
  void _initializeListener(Function(String) onScanned) {
    // If already initialized, dispose first to avoid memory leaks
    if (_isInitialized) {
      _disposeListener();
    }
    
    _isInitialized = true;
    onBarcodeScanned = onScanned;
    
    // Use a lower log level in production
    debugPrint("Hardware scanner event channel initializing");
    
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic scanData) {
        // Throttle incoming events
        if (_debounceTimer?.isActive ?? false) return;
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
        
        if (scanData != null && scanData.toString().isNotEmpty) {
          // Process on a separate isolate or using compute
          _processScanData(scanData.toString());
        }
      },
      onError: (dynamic error) {
        debugPrint("Hardware scanner error: $error");
      }
    );
    
    // Set up method channel handler for scanner button press
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "scannerKeyPressed") {
        String scannedData = call.arguments.toString();
        
        // Apply same debounce
        if (_debounceTimer?.isActive ?? false) return null;
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
        
        // Process on a separate isolate or using compute
        _processScanData(scannedData);
      }
      return null;
    });
  }
  
  // Process scan data - potentially move to compute
  void _processScanData(String data) {
    onBarcodeScanned?.call(data);
  }
  
  // Dispose scanner listener
  static void disposeScannerListener() {
    instance._disposeListener();
  }
  
  // Internal method to dispose the listener
  void _disposeListener() {
    _subscription?.cancel();
    _subscription = null;
    onBarcodeScanned = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isInitialized = false;
  }

  // Check if a key event is from the hardware scanner
  static bool isScannerButtonPressed(KeyEvent event) {
    // Common scanner button keycodes - adjusted for the hardware scanners
    const scannerKeyCodes = [120, 121, 122, 293, 294, 73014444552];
    final isScanner = scannerKeyCodes.contains(event.logicalKey.keyId);
    if (isScanner) {
      debugPrint("QR DEBUG: Hardware scanner key detected: ${event.logicalKey.keyId}");
    }
    return isScanner;
  }
  
  // Clear scanned barcodes history
  static void clearScannedBarcodes() {
    instance.scannedBarcodes.clear();
    debugPrint("QR DEBUG: Scanned barcodes history cleared");
  }
}