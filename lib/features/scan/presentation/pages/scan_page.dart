// Modified scan_page.dart
import 'package:architecture_scan_app/core/utils/debouncer.dart';
import 'package:architecture_scan_app/core/widgets/deduction_dialog.dart';
import 'package:architecture_scan_app/core/widgets/navbar_custom.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/key_code_constants.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../../data/datasources/scan_service_impl.dart';
import '../widgets/scan_widgets.dart';

class ScanPage extends StatefulWidget {
  final UserEntity user;

  const ScanPage({super.key, required this.user});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  final FocusNode _focusNode = FocusNode();

  // State variables
  bool _cameraActive = false;
  bool _torchEnabled = false;
  final bool _isSaving = false;
  bool _isDeductionDialogOpen = false;
  String? _currentScannedValue;
  DateTime? _lastSnackbarTime;
  String? _lastSnackbarMessage;
  DateTime? _lastScanTime;
  final List<List<String>> _scannedItems = [];
  final _scanDebouncer = Debouncer(milliseconds: 300);

  // Material data
  Map<String, String> _materialData = {
    'Material Name': '',
    'Material ID': '',
    'Quantity': '',
    'Receipt Date': '',
    'Supplier': '',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.requestFocus();

    compute(_initializeScanner, null).then((controller) {
      setState(() {
        _controller = controller;
      });
    });
    // Initialize hardware scanner listener
    ScanService.initializeScannerListener((scannedData) {
      debugPrint("QR DEBUG: Hardware scanner callback with data: $scannedData");
      
      // For hardware scanner, we'll directly add the event to the bloc
      // rather than calling _processScannedData, to ensure consistent state handling
      context.read<ScanBloc>().add(HardwareScanButtonPressed(scannedData));
      
      // Show feedback for hardware scanner
      _showSnackbar("Hardware scan: $scannedData", backgroundColor: Colors.green);
    });

    _initializeCameraController();
  }

  static MobileScannerController? _initializeScanner(_) {
  try {
    return MobileScannerController(
      formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      returnImage: false,
    );
  } catch (e) {
    debugPrint("Error initializing scanner: $e");
    return null;
  }
}

  @override
  void dispose() {
    _cleanUpCamera();
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    ScanService.disposeScannerListener();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cleanUpCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraActive) {
        _initializeCameraController();
      }
    }
  }

  // 2. Tách biệt việc khởi tạo controller và việc bật camera
  // In scan_page.dart, modify _initializeCameraController() method
  void _initializeCameraController() {
    _cleanUpCamera();

    try {
      _controller = MobileScannerController(
        // Simplify formats to improve compatibility
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
        ],
        // Critical for emulator compatibility
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        // Disable image return to reduce processing overhead
        returnImage: false,
        torchEnabled: _torchEnabled,
        // Add a reasonable timeout for initialization
        autoStart: false,
      );

      // Use a delayed start approach for emulators
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && _controller != null) {
          _controller!.start();
        }
      });

      context.read<ScanBloc>().add(InitializeScanner(_controller!));
      
      // Add debug logging
      debugPrint("QR DEBUG: Camera controller initialized with simplified settings");
    } catch (e) {
      debugPrint("QR DEBUG: ⚠️ Camera initialization error: $e");
      // Show a recoverable error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera initialization error: $e"),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _initializeCameraController(),
          ),
        ),
      );
    }
  }

  void _cleanUpCamera() {
    // Release camera controller properly
    if (_controller != null) {
      try {
        _controller?.stop();
        _controller?.dispose();
      } catch (e) {
        debugPrint("QR DEBUG: ⚠️ Error disposing camera: $e");
      }
      _controller = null;
    }
  }

  void _toggleCamera() {
    debugPrint("QR DEBUG: Toggle camera button pressed");
    setState(() {
      _cameraActive = !_cameraActive;

      if (_cameraActive) {
        try {
          if (_controller == null) {
            _initializeCameraController();
          }
          _controller!.start();
        } catch (e) {
          debugPrint("QR DEBUG: Error starting camera: $e");
          _cleanUpCamera();
          _initializeCameraController();
          _controller?.start();
        }
      } else if (_controller != null) {
        _controller?.stop();
      }
    });

    // Update bloc with camera state
    context.read<ScanBloc>().add(ToggleCamera(_cameraActive));
  }

  Future<void> _toggleTorch() async {
    debugPrint("QR DEBUG: Toggle torch button pressed");
    if (_controller != null) {
      final scanBloc = context.read<ScanBloc>();
      await _controller!.toggleTorch();
      if (!mounted) return;
      
      setState(() {
        _torchEnabled = !_torchEnabled;
      });

      // Update bloc with torch state
      scanBloc.add(ToggleTorch(_torchEnabled));
    }
  }

  Future<void> _switchCamera() async {
    debugPrint("QR DEBUG: Switch camera button pressed");
    if (_controller != null) {
      final scanBloc = context.read<ScanBloc>();
      await _controller!.switchCamera();
      if (!mounted) return;

      // Notify bloc
      scanBloc.add(SwitchCamera());
    }
  }

  // Controlled snackbar display method to prevent duplicates
  void _showSnackbar(String message, {Color backgroundColor = Colors.blue}) {
    // Prevent rapid duplicate snackbars
    final now = DateTime.now();
    if (_lastSnackbarTime != null &&
        now.difference(_lastSnackbarTime!).inSeconds < 2 &&
        _lastSnackbarMessage == message) {
      return; // Skip duplicate messages within 2 seconds
    }

    _lastSnackbarTime = now;
    _lastSnackbarMessage = message;

    // Hide any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    debugPrint(
      "QR DEBUG: === Barcode detected: ${capture.barcodes.length} ===",
    );

    if (capture.barcodes.isEmpty) {
      debugPrint("QR DEBUG: No barcodes detected in this frame");
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      final format = barcode.format;
      final corners = barcode.corners;

      debugPrint("QR DEBUG: ---------- BARCODE INFO ----------");
      debugPrint("QR DEBUG: Format: $format");
      debugPrint("QR DEBUG: RawValue: $rawValue");
      debugPrint("QR DEBUG: Has corners: ${corners.isNotEmpty}");
      if (corners.isNotEmpty) {
        debugPrint("QR DEBUG: Number of corners: ${corners.length}");
      }

      if (rawValue == null || rawValue.isEmpty) {
        debugPrint("QR DEBUG: ⚠️ Empty barcode value");
        continue;
      }

      // Print QR value in console
      debugPrint("QR DEBUG: ✅ QR value success: $rawValue");

      // Use controlled snackbar display
      _showSnackbar("Scanned QR: $rawValue");

      // Process barcode directly through BLoC
      context.read<ScanBloc>().add(BarcodeDetected(rawValue));

      // Stop processing after finding the first valid barcode
      break;
    }
  }

  // This method is now only used for UI updates
  void _updateUIFromMaterialInfo(Map<String, String> materialInfo, String barcode) {
    debugPrint("QR DEBUG: Updating UI with new material data");
    
    setState(() {
      _currentScannedValue = barcode;
      _materialData = Map<String, String>.from(materialInfo);

      // Add to scanned items list if not already present
      if (!_scannedItems.any((item) => item[0] == barcode)) {
        _scannedItems.add([barcode, 'Scanned', materialInfo['Quantity'] ?? '1']);
        debugPrint("QR DEBUG: Added to scanned items list");
      }
    });

    debugPrint("QR DEBUG: ✅ UI updated with material info");
    // Print material data values for checking
    _materialData.forEach((key, value) {
      debugPrint("QR DEBUG: $key: $value");
    });
  }

  // Thêm vào _showDeductionDialog trong scan_page.dart
Future<void> _saveData() async {
  debugPrint("QR DEBUG: Save button pressed");

  if (_materialData['Material ID']?.isEmpty ?? true) {
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No data to save'))
    );
    return;
  }

  if (!mounted) return;

  // Hiển thị dialog khấu trừ
  setState(() {
    _isDeductionDialogOpen = true;
  });

  try {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DeductionDialog(
        productName: _materialData['Material Name'] ?? '',
        productCode: _materialData['Material ID'] ?? '',
        currentQuantity: _materialData['Quantity'] ?? '0',
        onCancel: () {
          Navigator.of(dialogContext).pop();
          setState(() {
            _isDeductionDialogOpen = false;
          });
        },
        onConfirm: (deduction) {
          Navigator.of(dialogContext).pop();

          // Hiển thị dialog loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing data...'),
                ],
              ),
            ),
          );

          // Gửi event đến bloc
          context.read<ScanBloc>().add(
            ConfirmDeductionEvent(
              barcode: _materialData['code'] ?? _currentScannedValue!,
              quantity: _materialData['m_qty'] ?? _materialData['Quantity'] ?? '0',
              deduction: deduction,
              materialInfo: _materialData,
              userId: widget.user.name,
            ),
          );
        },
      ),
    );
  } catch (e) {
    setState(() {
      _isDeductionDialogOpen = false;
    });

    if(!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
    );
  }
}

  void _clearScannedItems() {
    debugPrint("QR DEBUG: Clear button pressed");

    // Capture the bloc reference before showing the dialog
    final scanBloc = context.read<ScanBloc>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Clear Scanned Items'),
            content: const Text(
              'Are you sure you want to clear all scanned items?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Use the captured bloc instead of trying to access it from dialogContext
                  scanBloc.add(StartNewScan());

                  // Clear local state
                  setState(() {
                    _scannedItems.clear();
                    _materialData = {
                      'Material Name': '',
                      'Material ID': '',
                      'Quantity': '',
                      'Receipt Date': '',
                      'Supplier': '',
                    };
                    _currentScannedValue = null;
                  });

                  Navigator.pop(dialogContext);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("QR DEBUG: Building QRScanPage");

    return BlocConsumer<ScanBloc, ScanState>(
      listener: (context, state) {
        // Critical fix: Update the UI based on BLoC state changes
        if (state is MaterialInfoLoaded) {
          // Update the local state with material info from the BLoC
          _updateUIFromMaterialInfo(state.materialInfo, state.currentBarcode);
        }
        
        if (Navigator.of(context).canPop() &&
            state is! ScanProcessingState &&
            state is! SavingDataState) {
          Navigator.of(context).pop();
        }
        
        if (state is ScanErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red)
          );
        } else if (state is DataSavedState) {
          // Hiển thị thông báo thành công
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('SUCCESS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              content: const Text('Data processed successfully'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    // Reset state
                    setState(() {
                      _isDeductionDialogOpen = false;
                      _materialData = {
                        'Material Name': '',
                        'Material ID': '',
                        'Quantity': '',
                        'Receipt Date': '',
                        'Supplier': '',
                      };
                      _currentScannedValue = null;
                    });
                    
                    // Reset scan
                    context.read<ScanBloc>().add(StartNewScan());
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'SCAN PAGE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue.shade700,
            centerTitle: true,
            actions: [
              // Control buttons moved to app bar
              IconButton(
                icon: Icon(
                  _torchEnabled ? Icons.flash_on : Icons.flash_off,
                  color: _torchEnabled ? Colors.yellow : Colors.white,
                ),
                onPressed: _cameraActive ? _toggleTorch : null,
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: _cameraActive ? _switchCamera : null,
              ),
              IconButton(
                icon: Icon(
                  _cameraActive ? Icons.stop : Icons.play_arrow,
                  color: _cameraActive ? Colors.red : Colors.white,
                ),
                onPressed: _toggleCamera,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _clearScannedItems,
              ),
            ],
          ),
          body: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              // Handle key events from hardware scanner
              if (event is KeyDownEvent) {
                debugPrint("QR DEBUG: Key pressed: ${event.logicalKey.keyId}");
                if (KeycodeConstants.scannerKeyCodes.contains(
                  event.logicalKey.keyId,
                )) {
                  debugPrint("QR DEBUG: Scanner key pressed");
                } else if (ScanService.isScannerButtonPressed(event)) {
                  debugPrint("QR DEBUG: Scanner key pressed via ScanService");
                }
              }
            },
            child: Column(
              children: [
                // QR Camera Section
                Container(
                  margin: const EdgeInsets.all(5),
                  child: QRScannerWidget(
                    controller: _controller,
                    onDetect: (capture) {
                      debugPrint(
                        "QR DEBUG: QRScannerWidget calls onDetect callback",
                      );
                      _onDetect(capture);
                    },
                    isActive: _cameraActive,
                    onToggle: () {
                      debugPrint(
                        "QR DEBUG: QRScannerWidget calls onToggle callback",
                      );
                      _toggleCamera();
                    },
                  ),
                ),

                // Material Info Section (table layout)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Column(
                      children: [
                        // Table-like layout for info
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFFAF1E6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                // Each info row as table row
                                _buildTableRow(
                                  'ID',
                                  _materialData['Material ID'] ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  'Material Name',
                                  _materialData['Material Name'] ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  'Quantity',
                                  _materialData['Quantity'] ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  'Receipt Date',
                                  _materialData['Receipt Date'] ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  'Supplier',
                                  _materialData['Supplier'] ?? '',
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Save button
                        Container(
                          width: 120,
                          height: 40,
                          margin: const EdgeInsets.only(top: 5, bottom: 5),
                          child: ElevatedButton(
                            onPressed: _saveData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child:
                                _isSaving
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomNavBar(
            currentIndex: 1,
            user: widget.user,
            disableNavigation: _isDeductionDialogOpen,
          ),
        );
      },
    );
  }

  // Helper methods for table layout
  Widget _buildTableRow(String label, String value) {
    return Expanded(
      child: Row(
        children: [
          // Label side (left)
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          // Value side (right)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                value.isEmpty ? 'No Scan data' : value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: value.isEmpty ? Colors.black : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 2);
  }
}