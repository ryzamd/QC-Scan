// lib/features/scan/data/datasources/scan_service_impl.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for handling hardware scanner integration
class ScanService {
  static const EventChannel _eventChannel = EventChannel('com.example.jsonplaceholder_app/scanner');
  static const MethodChannel _methodChannel = MethodChannel('com.example.jsonplaceholder_app');
  
  // Callback for scan events
  static Function(String)? onBarcodeScanned;
  
  // List to keep track of scanned barcodes
  static final List<String> scannedBarcodes = [];
  
  // Stream subscription for event channel
  static StreamSubscription? _subscription;

  // Initialize scanner listener
  static void initializeScannerListener(Function(String) onScanned) {
    onBarcodeScanned = onScanned;
    
    // Cancel any existing subscription
    _subscription?.cancel();
    
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic scanData) {
        if (scanData != null && scanData != "No Scan Data Found") {
          debugPrint("📱 Received scan data: $scanData");
          onBarcodeScanned?.call(scanData.toString());
          
          // Add to local history if not already there
          if (!scannedBarcodes.contains(scanData.toString())) {
            scannedBarcodes.add(scanData.toString());
          }
        }
      },
      onError: (dynamic error) {
        debugPrint("❌ Error receiving scan data: $error");
      }
    );
    
    // Set up method channel handler for scanner button press
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "scannerKeyPressed") {
        String scannedData = call.arguments.toString();
        debugPrint("🔑 Scanner key pressed: $scannedData");
        onBarcodeScanned?.call(scannedData);
      }
      return null;
    });
    
    // Log that we've initialized the scanner
    debugPrint("🚀 Scanner listener initialized");
  }
  
  // Dispose scanner listener
  static void disposeScannerListener() {
    _subscription?.cancel();
    _subscription = null;
    onBarcodeScanned = null;
    debugPrint("🛑 Scanner listener disposed");
  }

  // Check if a key event is from the hardware scanner
  static bool isScannerButtonPressed(KeyEvent event) {
    // Common scanner button keycodes - adjusted for the hardware scanners
    const scannerKeyCodes = [120, 121, 122, 293, 294];
    final isScanner = scannerKeyCodes.contains(event.logicalKey.keyId);
    if (isScanner) {
      debugPrint("🔍 Hardware scanner key detected: ${event.logicalKey.keyId}");
    }
    return isScanner;
  }
  
  // Clear scanned barcodes history
  static void clearScannedBarcodes() {
    scannedBarcodes.clear();
    debugPrint("🧹 Scanned barcodes history cleared");
  }
}