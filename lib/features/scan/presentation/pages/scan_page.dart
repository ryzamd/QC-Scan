// lib/features/scan/presentation/pages/scan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/dialog_custom.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../../data/datasources/scan_service_impl.dart';

class ScanPage extends StatefulWidget {
  final UserEntity user;
  
  const ScanPage({super.key, required this.user});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  bool _processingInProgress = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Set up widgets binding observer for hardware keyboard events
    WidgetsBinding.instance.addObserver(this);
    _focusNode.requestFocus();
    
    // Initialize scanner controller
    _scannerController = MobileScannerController(
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
      returnImage: false,
      torchEnabled: false,
    );
    
    // Initialize scanner controller in BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanBloc>().add(InitializeScanner(_scannerController));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive) {
      _scannerController.stop();
    }
  }

  void _clearScannedItems() {
    debugPrint("QR DEBUG: Clear button pressed");
    context.read<ScanBloc>().add(StartNewScan());
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        // Check if the key event is from a hardware scanner
        if (event is KeyDownEvent && ScanService.isScannerButtonPressed(event)) {
          debugPrint("💢 Hardware scanner button pressed");
          // Handle in the ScanService event channel
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            'SCAN PAGE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.network_wifi_1_bar_outlined, color: Colors.white),
              onPressed: () {},
              tooltip: 'Network',
            ),
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              onPressed: () {
                context.read<ScanBloc>().add(StartNewScan());
              },
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: Container(
                width: 16,
                height: 16,
                color: Colors.red,
              ),
              onPressed: () {
                final state = context.read<ScanBloc>().state;
                if (state is ScanningState) {
                  context.read<ScanBloc>().add(ToggleCamera(!state.isCameraActive));
                } else if (state is MaterialInfoLoaded) {
                  context.read<ScanBloc>().add(ToggleCamera(!state.isCameraActive));
                }
              },
              tooltip: 'Stop',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _clearScannedItems,
              tooltip: 'Clear',
            ),
          ],
        ),
        body: BlocConsumer<ScanBloc, ScanState>(
          listener: (context, state) {
            if (state is ScanErrorState) {
              // Show error dialog
              showDialog(
                context: context,
                builder: (context) => CustomAlertDialog(
                  title: 'Error',
                  message: state.message,
                  onConfirm: () => Navigator.pop(context),
                ),
              );
            } else if (state is ProcessingCompleteState && !_processingInProgress) {
              // Show success dialog
              _processingInProgress = true;
              showDialog(
                context: context,
                builder: (context) => CustomAlertDialog(
                  title: 'Success',
                  message: 'Data transferred to Processing successfully.',
                  onConfirm: () {
                    Navigator.of(context).pop();
                    _processingInProgress = false;
                  },
                ),
              );
            }
          },
          builder: (context, state) {
            // Get material info and camera status
            Map<String, String> materialInfo = {};
            bool isCameraActive = false;
            bool isLoading = false;
            String currentBarcode = '';
            
            if (state is ScanningState) {
              isCameraActive = state.isCameraActive;
            } else if (state is MaterialInfoLoaded) {
              isCameraActive = state.isCameraActive;
              materialInfo = state.materialInfo;
              currentBarcode = state.currentBarcode;
            } else if (state is SavingDataState) {
              isCameraActive = state.isCameraActive;
              materialInfo = state.materialInfo;
              currentBarcode = state.currentBarcode;
              isLoading = true;
            }
            
            return Column(
              children: [
                // Camera Scanner Section
                Container(
                  height: 280,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      // Camera View
                      if (isCameraActive) 
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (barcodes) {
                            if (barcodes.barcodes.isNotEmpty) {
                              final barcode = barcodes.barcodes.first;
                              if (barcode.rawValue != null) {
                                context.read<ScanBloc>().add(BarcodeDetected(barcode.rawValue!));
                              }
                            }
                          },
                          errorBuilder: (context, error, child) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red.shade600, size: 50),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Camera error: ${error.errorCode}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      _scannerController.stop();
                                      _scannerController.start();
                                    },
                                    child: const Text("Try Again"),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        const Center(
                          child: Text(
                            "Camera is off",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      
                      // Scan Frame - Red corners like in original UI
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Stack(
                              children: [
                                // Top Left Corner
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.red, width: 4),
                                        left: BorderSide(color: Colors.red, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Top Right Corner
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.red, width: 4),
                                        right: BorderSide(color: Colors.red, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Bottom Left Corner
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.red, width: 4),
                                        left: BorderSide(color: Colors.red, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Bottom Right Corner
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.red, width: 4),
                                        right: BorderSide(color: Colors.red, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Camera Controls
                Container(
                  height: 50,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flash_off),
                        onPressed: () {
                          _scannerController.toggleTorch();
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () {
                          _scannerController.switchCamera();
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Container(
                          width: 18,
                          height: 18,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          if (state is ScanningState) {
                            context.read<ScanBloc>().add(ToggleCamera(!state.isCameraActive));
                          } else if (state is MaterialInfoLoaded) {
                            context.read<ScanBloc>().add(ToggleCamera(!state.isCameraActive));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                // Material Info Section
                Expanded(
                  child: materialInfo.isNotEmpty
                      ? Column(
                          children: [
                            // Material Info Table
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildInfoRow("ID", materialInfo["Material ID"] ?? currentBarcode),
                                  _buildInfoRow("Material Name", materialInfo["Material Name"] ?? "Material ${currentBarcode.hashCode % 1000}"),
                                  _buildInfoRow("Quantity", materialInfo["Quantity"] ?? "21"),
                                  _buildInfoRow("Receipt Date", materialInfo["Receipt Date"] ?? DateTime.now().toString().substring(0, 19)),
                                  _buildInfoRow("Supplier", materialInfo["Supplier"] ?? "Supplier ${currentBarcode.hashCode % 5 + 1}"),
                                ],
                              ),
                            ),
                            
                            // Save Button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () {
                                  if (state is MaterialInfoLoaded) {
                                    context.read<ScanBloc>().add(SaveScannedData(
                                      barcode: state.currentBarcode,
                                      quantity: materialInfo['Quantity'] ?? '1',
                                      materialInfo: materialInfo,
                                      userId: widget.user.userId,
                                    ));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.grey,
                                ),
                                child: isLoading 
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Scan a QR code or barcode to see material information',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
                
                // Bottom Navigation
                Container(
                  height: 60,
                  color: Colors.blue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.business_center, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.processRecords,
                            arguments: widget.user,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  // Build info row similar to your existing UI
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        // Label side (blue background)
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          color: Colors.blue,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Value side (light background)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: const Color(0xFFF8F8F8),
            child: Text(
              value.isEmpty ? 'No data available' : value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}