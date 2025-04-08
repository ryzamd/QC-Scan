// Modified scan_page.dart
import 'package:architecture_scan_app/core/widgets/deduction_dialog.dart';
import 'package:architecture_scan_app/core/widgets/navbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver, RouteAware {
  final FocusNode _focusNode = FocusNode();
  bool _isDeductionDialogOpen = false;
  late final bool _isQC2User;
  
  // Material data - this is UI state only
  Map<String, String> _materialData = {
    'Material Name': '',
    'Material ID': '',
    'Quantity': '',
    'Receipt Date': '',
    'Supplier': '',
  };
  String? _currentScannedValue;

  @override
  void initState() {
    super.initState();
    _isQC2User = widget.user.name == "品管正式倉";
    WidgetsBinding.instance.addObserver(this);
    _focusNode.requestFocus();
    
    // Initialize scan service through bloc
    context.read<ScanBloc>().add(InitializeScanService());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    // Được gọi khi màn hình này được push vào stack
    // Không làm gì với camera ở đây vì mặc định camera tắt
  }

  @override
  void didPop() {
    // Được gọi khi màn hình này bị pop khỏi stack
  }

  @override
  void didPushNext() {
    // Được gọi khi một màn hình khác được push lên trên màn hình này
  }

  @override
  void didPopNext() {
    // Được gọi khi màn hình phía trên được pop ra
    // Không tự động khởi tạo lại camera
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Turn off camera when app is paused/inactive
      if (mounted) {
        context.read<ScanBloc>().add(const ToggleCamera(false));
      }
    }
  }

  Future<void> _showDeductionDialog() async {
    if (_materialData['Material ID']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to save'))
      );
      
      return;
    }

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

            // Show loading dialog
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

            context.read<ScanBloc>().add(
              ConfirmDeductionEvent(
                barcode: _materialData['code'] ?? _currentScannedValue!,
                quantity: _materialData['m_qty'] ?? _materialData['Quantity'] ?? '0',
                deduction: deduction,
                materialInfo: _materialData,
                userId: widget.user.name,
                isQC2User: _isQC2User,
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
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("QR DEBUG: Building QRScanPage");

    return BlocConsumer<ScanBloc, ScanState>(
      listener: (context, state) {
        if (state is MaterialInfoLoaded) {
          setState(() {
            _currentScannedValue = state.currentBarcode;
            _materialData = Map<String, String>.from(state.materialInfo);
          });
        }

        if (Navigator.of(context).canPop() &&
            state is! ScanProcessingState &&
            state is! SavingDataState) {
          Navigator.of(context).pop();
        }

          if (state is ShowClearConfirmationState) {
            _showClearConfirmationDialog(context);
          } else if (state is ScanningState && state.scannedItems.isEmpty) {
            // Khi quay về ScanningState với danh sách rỗng, reset UI
            setState(() {
              _materialData = {
                'Material Name': '',
                'Material ID': '',
                'Quantity': '',
                'Receipt Date': '',
                'Supplier': '',
                'Unit': '',
              };
              _currentScannedValue = null;
            });
          }

          if (state is ScanErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DataSavedState) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: const Text(
                      'SUCCESS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text('Data processed successfully'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();

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
          bool isCameraActive = false;
          bool isTorchEnabled = false;
          bool isProcessing =
              state is ScanProcessingState || state is SavingDataState;

          if (state is ScanningState) {
            isCameraActive = state.isCameraActive;
            isTorchEnabled = state.isTorchEnabled;
          } else if (state is MaterialInfoLoaded) {
            isCameraActive = state.isCameraActive;
            isTorchEnabled = state.isTorchEnabled;
          }

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
                // Camera control buttons
                IconButton(
                  icon: Icon(
                    isTorchEnabled ? Icons.flash_on : Icons.flash_off,
                    color: isTorchEnabled ? Colors.yellow : Colors.white,
                  ),
                  onPressed:
                      isCameraActive
                          ? () => context.read<ScanBloc>().add(
                            ToggleTorch(!isTorchEnabled),
                          )
                          : null,
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed:
                      isCameraActive
                          ? () => context.read<ScanBloc>().add(SwitchCamera())
                          : null,
                ),
                IconButton(
                  icon: Icon(
                    isCameraActive ? Icons.stop : Icons.play_arrow,
                    color: isCameraActive ? Colors.red : Colors.white,
                  ),
                  onPressed:
                      () => context.read<ScanBloc>().add(
                        ToggleCamera(!isCameraActive),
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed:
                      () => context.read<ScanBloc>().add(ClearScannedItems()),
                ),
              ],
            ),
            body: KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (KeyEvent event) {
                // Handle key events from hardware scanner
                if (event is KeyDownEvent) {
                  debugPrint(
                    "QR DEBUG: Key pressed: ${event.logicalKey.keyId}",
                  );
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
                      controller:
                          state is ScanningState
                              ? state.controller
                              : state is MaterialInfoLoaded
                              ? state.controller
                              : null,
                      onDetect: (capture) {
                        if (capture.barcodes.isNotEmpty) {
                          final barcode = capture.barcodes.first;
                          if (barcode.rawValue != null &&
                              barcode.rawValue!.isNotEmpty) {
                            // Dispatch to bloc
                            context.read<ScanBloc>().add(
                              BarcodeDetected(barcode.rawValue!),
                            );
                          }
                        }
                      },
                      isActive: isCameraActive,
                      onToggle: () {
                        context.read<ScanBloc>().add(
                          ToggleCamera(!isCameraActive),
                        );
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

                          Container(
                            width: 120,
                            height: 40,
                            margin: const EdgeInsets.only(top: 5, bottom: 5),
                            child: ElevatedButton(
                              onPressed: _showDeductionDialog,
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
                                  isProcessing
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

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text(
              'CLEAR DATA',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Are you sure you want to clear all scanned data?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<ScanBloc>().add(CancelClearScannedItems());
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _materialData = {
                      'Material Name': '',
                      'Material ID': '',
                      'Quantity': '',
                      'Receipt Date': '',
                      'Supplier': '',
                      'Unit': '',
                    };
                    _currentScannedValue = null;
                  });
                  context.read<ScanBloc>().add(ConfirmClearScannedItems());
                },
                child: const Text('OK', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 2);
  }
}
