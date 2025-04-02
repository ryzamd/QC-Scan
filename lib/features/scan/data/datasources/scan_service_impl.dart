// Fixed implementation for ScanService class
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for handling hardware scanner integration
class ScanService {
  static const EventChannel _eventChannel = EventChannel('com.example.architecture_scan_app/scanner');
  static const MethodChannel _methodChannel = MethodChannel('com.example.architecture_scan_app');
  
  // Callback for scan events
  static Function(String)? onBarcodeScanned;
  
  // List to keep track of scanned barcodes
  static final List<String> scannedBarcodes = [];
  
  // Stream subscription for event channel
  static StreamSubscription? _subscription;
  
  // Debounce timer to avoid duplicate scans
  static Timer? _debounceTimer;
  
  // Flag to track if the service is initialized
  static bool _isInitialized = false;

  // Initialize scanner listener
  static void initializeScannerListener(Function(String) onScanned) {
    // If already initialized, dispose first to avoid memory leaks
    if (_isInitialized) {
      disposeScannerListener();
    }
    
    _isInitialized = true;
    onBarcodeScanned = onScanned;
    
    debugPrint("QR DEBUG: Initializing hardware scanner event channel");
    
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic scanData) {
        debugPrint("QR DEBUG: 📟 Hardware scanner data received: $scanData");
        if (scanData != null && scanData.toString().isNotEmpty) {
          // Apply debounce to avoid duplicate scans
          if (_debounceTimer?.isActive ?? false) {
            debugPrint("QR DEBUG: Debouncing rapid scan");
            return;
          }
          
          _debounceTimer = Timer(const Duration(milliseconds: 500), () {});
          
          // Process the data from hardware scanner
          onBarcodeScanned?.call(scanData.toString());
          
          // Add to local history if not already there
          if (!scannedBarcodes.contains(scanData.toString())) {
            scannedBarcodes.add(scanData.toString());
          }
        }
      },
      onError: (dynamic error) {
        debugPrint("QR DEBUG: ❌ Hardware scanner error: $error");
      }
    );
    
    // Set up method channel handler for scanner button press
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      debugPrint("QR DEBUG: Method channel called: ${call.method}");
      if (call.method == "scannerKeyPressed") {
        String scannedData = call.arguments.toString();
        debugPrint("QR DEBUG: Scanner key pressed: $scannedData");
        
        // Apply same debounce as above
        if (_debounceTimer?.isActive ?? false) {
          debugPrint("QR DEBUG: Debouncing rapid scan");
          return null;
        }
        
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {});
        onBarcodeScanned?.call(scannedData);
      }
      return null;
    });
    
    debugPrint("QR DEBUG: Hardware scanner initialized");
    
    // Send a test event after initialization to check if channel is working
    try {
      _methodChannel.invokeMethod('testScanEvent');
    } catch (e) {
      debugPrint("QR DEBUG: Error invoking test method: $e");
    }
  }
  
  // Dispose scanner listener
  static void disposeScannerListener() {
    _subscription?.cancel();
    _subscription = null;
    onBarcodeScanned = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isInitialized = false;
    debugPrint("QR DEBUG: Scanner listener disposed");
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
    scannedBarcodes.clear();
    debugPrint("QR DEBUG: Scanned barcodes history cleared");
  }
}