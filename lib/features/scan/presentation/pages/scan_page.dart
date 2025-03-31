import 'package:architecture_scan_app/core/widgets/navbar_custom.dart';
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
  bool _isSaving = false;
  String? _currentScannedValue;
  DateTime? _lastSnackbarTime;
  String? _lastSnackbarMessage;
  DateTime? _lastScanTime;
  final List<List<String>> _scannedItems = [];

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

    // Initialize hardware scanner listener
    ScanService.initializeScannerListener((scannedData) {
      debugPrint("QR DEBUG: Hardware scanner callback with data: $scannedData");
      _processScannedData(scannedData, isFromHardwareScanner: true);
    });

    _initializeCamera();
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
        _initializeCamera();
      }
    }
  }

  void _initializeCamera() {
    // Dispose of any existing controller first
    _cleanUpCamera();

    debugPrint("QR DEBUG: Initializing camera scanner");

    try {
      // Create a new controller with appropriate settings
      _controller = MobileScannerController(
        // Include all common barcode formats
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.codabar,
        ],
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        returnImage: false, // Optimize memory
        torchEnabled: _torchEnabled,
      );

      setState(() {
        _cameraActive = true;
      });

      if (_cameraActive) {
        debugPrint("QR DEBUG: Starting camera scanner");
        _controller?.start();
      }

      debugPrint("QR DEBUG: Camera initialization successful");

      // Initialize scanner in BLoC
      context.read<ScanBloc>().add(InitializeScanner(_controller!));
    } catch (e) {
      debugPrint("QR DEBUG: ⚠️ Camera initialization error: $e");

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera initialization error: $e"),
          backgroundColor: Colors.red,
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
          _initializeCamera();
        } else {
          _controller!.start();
        }
      } catch (e) {
        debugPrint("QR DEBUG: Error starting camera: $e");
        // Nếu có lỗi, thử tạo controller mới
        _cleanUpCamera();
        _initializeCamera();
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
      await _controller!.toggleTorch();
      setState(() {
        _torchEnabled = !_torchEnabled;
      });

      // Update bloc with torch state
      context.read<ScanBloc>().add(ToggleTorch(_torchEnabled));
    }
  }

  Future<void> _switchCamera() async {
    debugPrint("QR DEBUG: Switch camera button pressed");
    if (_controller != null) {
      await _controller!.switchCamera();

      // Notify bloc
      context.read<ScanBloc>().add(SwitchCamera());
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
      debugPrint("QR DEBUG: Has corners: ${corners != null}");
      if (corners != null) {
        debugPrint("QR DEBUG: Number of corners: ${corners.length}");
      }

      if (rawValue == null || rawValue.isEmpty) {
        debugPrint("QR DEBUG: ⚠️ Empty barcode value");
        continue;
      }

      // Print QR value in console
      debugPrint("QR DEBUG: ✅ QR value success: $rawValue");

      // Process barcode directly
      _processScannedData(rawValue);

      // Use controlled snackbar display
      _showSnackbar("Scanned QR: $rawValue");

      // Process barcode through BLoC as well
      context.read<ScanBloc>().add(BarcodeDetected(rawValue));

      // Stop processing after finding the first valid barcode
      break;
    }
  }

  void _processScannedData(String data, {bool isFromHardwareScanner = false}) {
    debugPrint(
      "QR DEBUG: Starting to process scanned data: $data (Hardware: $isFromHardwareScanner)",
    );

    if (data.isEmpty) {
      debugPrint("QR DEBUG: ⚠️ Empty data, skipping");
      return;
    }

    // Implement debounce for rapid scans
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 500) {
      debugPrint("QR DEBUG: ⚠️ Scan too fast, ignoring");
      return;
    }
    _lastScanTime = now;

    // Skip if already processed this data
    if (_currentScannedValue == data) {
      debugPrint("QR DEBUG: ⚠️ Data already processed, skipping");

      // Still show feedback for hardware scanner, even if duplicate
      if (isFromHardwareScanner) {
        _showSnackbar("Already scanned: $data", backgroundColor: Colors.orange);
      }
      return;
    }

    debugPrint("QR DEBUG: Updating UI with new data");

    try {
      setState(() {
        _currentScannedValue = data;

        // Process data into material information
        if (data.contains('/')) {
          debugPrint("QR DEBUG: Format contains '/'");
          _materialData = {
            'Material Name':
                '本白1-400ITPG 荷布DJT-8543 GUSTI TEX EPM 100% 315G 44"',
            'Material ID': data,
            'Quantity': '50.5',
            'Receipt Date': DateTime.now().toString().substring(0, 19),
            'Supplier': 'DONGJIN-USD',
          };
        } else {
          debugPrint("QR DEBUG: Standard format");
          _materialData = {
            'Material Name': 'Material ${data.hashCode % 1000}',
            'Material ID': data,
            'Quantity': '${(data.hashCode % 100).abs() + 10}',
            'Receipt Date': DateTime.now().toString().substring(0, 19),
            'Supplier': 'Supplier ${data.hashCode % 5 + 1}',
          };
        }

        // Add to scanned items list if not already present
        if (!_scannedItems.any((item) => item[0] == data)) {
          _scannedItems.add([data, 'Scanned', '1']);
          debugPrint("QR DEBUG: Added to scanned items list");
        }
      });

      // Update BLoC with the scanned data for further processing
      context.read<ScanBloc>().add(GetMaterialInfoEvent(data));

      // Show appropriate feedback
      if (isFromHardwareScanner) {
        _showSnackbar("Hardware scan: $data", backgroundColor: Colors.green);
      }

      debugPrint("QR DEBUG: ✅ Data processing successful");
      // Print material data values for checking
      _materialData.forEach((key, value) {
        debugPrint("QR DEBUG: $key: $value");
      });
    } catch (e) {
      debugPrint("QR DEBUG: ⚠️ Error processing data: $e");
      _showSnackbar("Error processing data: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _saveData() async {
    debugPrint("QR DEBUG: Save button pressed");

    if (_materialData['Material ID']?.isEmpty ?? true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to save')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Use BLoC to save the data
    if (_currentScannedValue != null) {
      context.read<ScanBloc>().add(
        SaveScannedData(
          barcode: _currentScannedValue!,
          quantity: _materialData['Quantity'] ?? '1',
          materialInfo: _materialData,
          userId: widget.user.userId,
        ),
      );
    }

    // Simulate data saving process
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
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
                      'ID Number': '',
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
        // Update local state based on bloc state changes
        if (state is MaterialInfoLoaded) {
          debugPrint(
            "QR DEBUG: MaterialInfoLoaded state received with data: ${state.materialInfo}",
          );

          // Map keys from repository to UI format
          Map<String, String> formattedData = {
            'Material Name': state.materialInfo['Material Name'] ?? '',
            'ID Number':
                state.materialInfo['Material ID'] ??
                state.materialInfo['ID Number'] ??
                state.currentBarcode,
            'Quantity': state.materialInfo['Quantity'] ?? '1',
            'Receipt Date':
                state.materialInfo['Receipt Date'] ??
                state.materialInfo['Scan Time'] ??
                DateTime.now().toString().substring(0, 19),
            'Supplier': state.materialInfo['Supplier'] ?? '',
          };

          setState(() {
            _materialData = formattedData;
            _currentScannedValue = state.currentBarcode;

            // Add to scanned items if not already present
            if (!_scannedItems.any((item) => item[0] == state.currentBarcode)) {
              _scannedItems.add([state.currentBarcode, 'Scanned', '1']);
            }
          });
        } else if (state is ScanErrorState) {
          _showSnackbar(state.message, backgroundColor: Colors.red);
        } else if (state is DataSavedState) {
          _showSnackbar('Saved successfully', backgroundColor: Colors.green);
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
          bottomNavigationBar: const CustomNavBar(currentIndex: 1),
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
                  fontSize: 16,
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
