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
import '../../data/models/scan_record_model.dart';
import '../../domain/entities/scan_record_entity.dart';
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

  ScanRecordEntity? _currentScanRecord;

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
    if (_currentScanRecord == null) {
      NotificationDialog.showAsync(
        context: context,
        title: 'NO DATA TO SAVE',
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

      final double? deductionQC1 = double.tryParse(_currentScanRecord!.materialInfo['Deduction_QC1']!);
      final double? deductionQC2 = double.tryParse(_currentScanRecord!.materialInfo['Deduction_QC2']!);
      final double actualQuantity = deductionQC1! - deductionQC2!;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DeductionDialog(
        productName: _currentScanRecord!.materialInfo['Material Name'] ?? '',
        productCode: _currentScanRecord!.code,
        currentQuantity: actualQuantity.toString(),
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
                barcode: _currentScanRecord!.code,
                quantity: actualQuantity.toString(),
                deduction: deduction,
                materialInfo: _currentScanRecord!.materialInfo,
                userId: widget.user.name,
                qcQtyOut: _currentScanRecord!.qcQtyOut,
                qcQtyIn: _currentScanRecord!.qcQtyIn,
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
        title: 'ERROR',
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
            _currentScanRecord = ScanRecordModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              code: state.currentBarcode,
              status: 'Pending',
              quantity: state.materialInfo['Quantity'] ?? '0',
              timestamp: DateTime.now(),
              userId: widget.user.userId,
              materialInfo: state.materialInfo,
              qcQtyOut: double.tryParse(state.materialInfo['qc_qty_out'] ?? '0') ?? 0.0,
              qcQtyIn: double.tryParse(state.materialInfo['qc_qty_in'] ?? '0') ?? 0.0,
            );
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
            _showClearConfirmationDialogAsync(context);

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
                  _currentScanRecord = null;
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
                if (event is KeyDownEvent) {
                  debugPrint(
                    "QR DEBUG: Key pressed: ${event.logicalKey.keyId}",
                  );
                  if (KeycodeConstants.scannerKeyCodes.contains(
                    event.logicalKey.keyId,
                  )) {
                    debugPrint("QR DEBUG: Scanner key pressed");
                  } else {
                    ScanService.isScannerButtonPressedAsync(event).then((isPressed) {
                      if (isPressed) {
                        debugPrint("QR DEBUG: Scanner key pressed via ScanService");
                      }
                    });
                  }
                }
              },
              child: Column(
                children: [
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
                                  _buildTableRow(
                                    '名稱',
                                    _currentScanRecord?.materialInfo['Material Name'] ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '總數',
                                    _currentScanRecord?.quantity ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '扣碼',
                                    _currentScanRecord?.materialInfo['Deduction_QC2'] ?? '0',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '日期',
                                    _currentScanRecord?.materialInfo['Receipt Date'] ?? '',
                                  ),
                                  _buildDivider(),
                                  _buildTableRow(
                                    '供應商',
                                    _currentScanRecord?.materialInfo['Supplier'] ?? '',
                                  ),
                                    _buildDivider(),
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

  Future<void> _showClearConfirmationDialogAsync(BuildContext context) async {
    final result = await ConfirmationDialog
                  .showAsync(
                    context: context,
                    title: 'CLEAR DATA',
                    message: 'Are you sure you want to clear all scanned data?',
                    showCancelButton: true,
                    confirmText: 'OK',
                    cancelText: 'Cancel',
                    titleColor: Colors.red,
                    confirmColor: Colors.red,
                    cancelColor: Colors.grey,
                   );
    if (result == true && context.mounted) {
      setState(() {
        _currentScanRecord = null;
      });
      context.read<ScanBloc>().add(ConfirmClearScannedItems());
    }
  }

  Widget _buildDivider() {
    return const SizedBox(height: 2);
  }
}
