// Modified scan_page.dart
import 'package:architecture_scan_app/core/widgets/confirmation_dialog.dart';
import 'package:architecture_scan_app/core/widgets/deduction_dialog.dart';
import 'package:architecture_scan_app/core/widgets/loading_dialog.dart';
import 'package:architecture_scan_app/core/widgets/navbar_custom.dart';
import 'package:architecture_scan_app/core/widgets/notification_dialog.dart';
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

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  bool _isDeductionDialogOpen = false;
  late final bool _isQC2User;
  
  Map<String, String> _materialData = {
    'Material Name': '',
    'Quantity': '',
    'Deduction': '',
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (mounted) {
        context.read<ScanBloc>().add(const ToggleCamera(false));
      }
    }
  }

  Future<void> _showDeductionDialogAsync() async {
    if (_materialData['Material ID']?.isEmpty ?? true) {
      NotificationDialog.showAsync(
        context: context,
        title: 'No data to save',
        message: 'Please scan a barcode first.',
        titleColor: Colors.red,
        buttonColor: Colors.red,
        onButtonPressed: () {},
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

            LoadingDialog.showAsync(
              context: context,
              message: 'Processing data...',
            );

            context.read<ScanBloc>().add(
              ConfirmDeductionEvent(
                barcode: _materialData['code'] ?? _currentScannedValue!,
                quantity: _materialData['m_qty'] ?? _materialData['Quantity'] ?? '0',
                deduction: deduction,
                materialInfo: _materialData,
                userId: widget.user.name,
                qcQtyOut: double.tryParse((_materialData['Deduction']).toString()) ?? 0.0,
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
      NotificationDialog.showAsync(
        context: context,
        title: 'Error',
        message: 'An error occurred while processing the data.',
        titleColor: Colors.red,
        buttonColor: Colors.red,
        onButtonPressed: () {},
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

        if (state is! ScanProcessingState && state is! SavingDataState) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          if (_isDeductionDialogOpen) {
              setState(() {
              _isDeductionDialogOpen = false;
            });
          }
        }

          if (state is ShowClearConfirmationState) {
            _showClearConfirmationDialog(context);

          } else if (state is ScanningState && state.scannedItems.isEmpty) {
            setState(() {
              _materialData = {
                'Material Name': '',
                'Quantity': '',
                'Deduction': '',
                'Receipt Date': '',
                'Supplier': '',
                'Unit': '',
              };
              _currentScannedValue = null;
            });
          }

          if (state is ScanErrorState) {
              NotificationDialog.showAsync(
                context: context,
                title: 'ERROR',
                message: state.message,
                titleColor: Colors.red,
                buttonColor: Colors.red,
                onButtonPressed: () {},
              );
          } else if (state is DataSavedState) {
            NotificationDialog.showAsync(
              context: context,
              title: 'SUCCESS',
              message: 'Data processed successfully',
              titleColor: Colors.green,
              buttonColor: Colors.green,
              onButtonPressed: () {
                setState(() {
                  _isDeductionDialogOpen = false;
                  _materialData = {
                    'Material Name': '',
                    'Quantity': '',
                    'Deduction': '',
                    'Receipt Date': '',
                    'Supplier': '',
                  };
                  _currentScannedValue = null;
                });
              },
            );
          }
  
        },
        builder: (context, state) {
          bool isCameraActive = false;
          bool isTorchEnabled = false;

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
                IconButton(
                  icon: Icon(
                    isTorchEnabled ? Icons.flash_on : Icons.flash_off,
                    color: isTorchEnabled ? Colors.yellow : Colors.white,
                  ),
                   onPressed: () => context.read<ScanBloc>().add(ToggleTorch(!isTorchEnabled)),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => context.read<ScanBloc>().add(SwitchCamera()),
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
                      controller: state is ScanningState ? state.controller : state is MaterialInfoLoaded
                                    ? state.controller : null,
                      onDetect: (capture) {
                        if (capture.barcodes.isNotEmpty) {
                          final barcode = capture.barcodes.first;
                          if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
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
                                    '名稱',
                                    _materialData['Material Name'] ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '總數',
                                    _materialData['Quantity'] ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '扣碼',
                                    _materialData['Deduction'] ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '日期',
                                    _materialData['Receipt Date'] ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '供應商',
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
                              onPressed: _showDeductionDialogAsync,
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
                              child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),),
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
            width: 80,
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
                fontSize: 14,
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
      ConfirmationDialog.showAsync(
        context: context,
        title: 'CLEAR DATA',
        message: 'Are you sure you want to clear all scanned data?',
        showCancelButton: true,
        confirmText: 'OK',
        cancelText: 'Cancel',
        titleColor: Colors.red,
        confirmColor: Colors.red,
        cancelColor: Colors.grey,
        onConfirm: () {
          setState(() {
            _materialData = {
              'Material Name': '',
              'Quantity': '',
              'Deduction': '',
              'Receipt Date': '',
              'Supplier': '',
              'Unit': '',
            };
            _currentScannedValue = null;
          });
          context.read<ScanBloc>().add(ConfirmClearScannedItems());
        },
      );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 2);
  }
}
