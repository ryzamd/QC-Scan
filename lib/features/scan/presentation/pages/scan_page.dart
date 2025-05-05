import 'package:architecture_scan_app/core/constants/app_colors.dart';
import 'package:architecture_scan_app/core/localization/context_extension.dart';
import 'package:architecture_scan_app/core/widgets/confirmation_dialog.dart';
import 'package:architecture_scan_app/core/widgets/deduction_dialog.dart';
import 'package:architecture_scan_app/core/widgets/error_dialog.dart';
import 'package:architecture_scan_app/core/widgets/loading_dialog.dart';
import 'package:architecture_scan_app/core/widgets/notification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/key_code_constants.dart';
import '../../../../core/services/get_translate_key.dart';
import '../../../../core/widgets/scafford_custom.dart';
import '../../../auth/login/domain/entities/user_entity.dart';
import '../../data/models/scan_record_model.dart';
import '../../domain/entities/scan_record_entity.dart';
import '../bloc/camera_bloc.dart';
import '../bloc/camera_event.dart';
import '../bloc/camera_state.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../../data/datasources/scan_service_impl.dart';
import '../widgets/scan_widgets.dart';

class ScanPage extends StatefulWidget {
  final UserEntity user;
  final bool isSpecialFeature;
  

  const ScanPage({
    super.key,
    required this.user,
    required this.isSpecialFeature,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  bool _isDeductionDialogOpen = false;
  ScanRecordEntity? _currentScanRecord;
  bool isQC2 = false;
  int optionFunction = 2;

  CameraBloc? _cameraBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.requestFocus();
    
    ScanService.initializeScannerListenerAsync((barcode) {
      context.read<ScanBloc>().add(BarcodeDetected(barcode));
    });
    context.read<CameraBloc>().add(InitializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    ScanService.disposeScannerListenerAsync();
    _cameraBloc?.add(CleanupCamera());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final currentRoute = ModalRoute.of(context)?.settings.name;
    isQC2 = currentRoute == AppRoutes.processingQC2;

    _cameraBloc ??= context.read<CameraBloc>();
  }

  Future<void> _showDeductionDialogAsync() async {
    if (_currentScanRecord == null) {
      NotificationDialog.showAsync(
        context: context,
        title: context.multiLanguage.noDataTitleUPCASE,
        message: context.multiLanguage.noDataMessage,
        buttonText: context.multiLanguage.okButtonUPCASE,
        titleColor: Colors.red,
        buttonColor: Colors.red,
        onButtonPressed: () {},
      );
      return;
    }

    setState(() {
      _isDeductionDialogOpen = true;
    });

    final scanBloc = context.read<ScanBloc>();
    List<String> availableReasons = scanBloc.getAvailableReasons();
    List<String> previouslySelectedReasons = [];
  
      if (widget.isSpecialFeature && optionFunction == 2) {
        try {
          final String? reasonsString = _currentScanRecord!.materialInfo['qc_reason'];
          
          if (reasonsString != null && reasonsString.isNotEmpty) {
            previouslySelectedReasons = reasonsString.split(' | ');
          }
        } catch (e) {
          debugPrint('Error parsing previously selected reasons: $e');
        }
      }

      if (availableReasons.isEmpty) {
        await scanBloc.remoteDataSource.getDeductionReasonsAsync().then((reasons) {
          availableReasons = reasons;
        });
      }

    if (!mounted) return;

    try {
      final double? deductionQC1 = double.tryParse( _currentScanRecord?.quantity ?? '0');
      final double? deductionQC2 = double.tryParse(_currentScanRecord!.materialInfo['Deduction_QC2']!);
      final double actualQuantity = deductionQC1! - deductionQC2!;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DeductionDialog(
          productName: _currentScanRecord!.materialInfo['Material Name'] ?? '',
          productCode: _currentScanRecord!.code,
          currentQuantity: optionFunction == 1 ? actualQuantity.toString() : deductionQC2.toString(),
          availableReasons: availableReasons,
          selectedReasons: previouslySelectedReasons,
          optionFunction: optionFunction,
          onCancel: () {
            Navigator.of(dialogContext).pop();
            setState(() {
              _isDeductionDialogOpen = false;
            });
          },
          onConfirm: (deduction, reasons) async {
            context.read<ScanBloc>().add(
              widget.isSpecialFeature ?
                ConfirmDeductionEvent(
                  barcode: _currentScanRecord!.code,
                  quantity: actualQuantity.toString(),
                  deduction: deduction,
                  materialInfo: _currentScanRecord!.materialInfo,
                  userId: widget.user.name,
                  qcQtyOut: _currentScanRecord!.qcQtyOut,
                  qcQtyIn: _currentScanRecord!.qcQtyIn,
                  isQC2User: widget.isSpecialFeature,
                  optionFunction: optionFunction,
                  reasons: reasons,
                )
                : ConfirmDeductionEvent(
                  barcode: _currentScanRecord!.code,
                  quantity: actualQuantity.toString(),
                  deduction: deduction,
                  materialInfo: _currentScanRecord!.materialInfo,
                  userId: widget.user.name,
                  qcQtyOut: _currentScanRecord!.qcQtyOut,
                  qcQtyIn: _currentScanRecord!.qcQtyIn,
                  isQC2User: widget.isSpecialFeature,
                  reasons: reasons,
                )
            );
            
            LoadingDialog.showAsync(
              context: context,
              message: context.multiLanguage.processingLoadingMessage,
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
        title: context.multiLanguage.errorTitleUPCASE,
        message: context.multiLanguage.processingErorrMessage,
        titleColor: Colors.red,
        buttonColor: Colors.red,
        onButtonPressed: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanBloc, ScanState>(
      listener: (context, state) {
        switch (state) {
          case ScanProcessingState():
          case SavingDataState():
            LoadingDialog.showAsync(context: context, message: context.multiLanguage.loadingMessage);
          default:
            LoadingDialog.hideAsync(context);
        }

        switch (state) {
          case MaterialInfoLoaded(:final currentBarcode, :final materialInfo):
            setState(() {
              _currentScanRecord = ScanRecordModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                code: currentBarcode,
                status: 'Pending',
                quantity: materialInfo['Quantity'] ?? '0',
                timestamp: DateTime.now(),
                userId: widget.user.userId,
                materialInfo: materialInfo,
                qcQtyOut: double.tryParse(materialInfo['qc_qty_out'] ?? '0') ?? 0.0,
                qcQtyIn: double.tryParse(materialInfo['qc_qty_in'] ?? '0') ?? 0.0,
              );

              
            });
            break;

          case DataSavedState():
          case ScanErrorState():
            if (_isDeductionDialogOpen) {
              setState(() {
                _isDeductionDialogOpen = false;
              });
            }
            LoadingDialog.hideAsync(context);

            if (state is ScanErrorState) {
              ErrorDialog.showAsync(
                context,
                title: context.multiLanguage.errorTitleUPCASE,
                message: TranslateKey.getStringKey(context.multiLanguage, state.message),
                onDismiss: () {},
              );
            } else {
              NotificationDialog.showAsync(
                context: context,
                title: context.multiLanguage.successTitleUPCASE,
                message: context.multiLanguage.dataProcessedSuccessMessage,
                titleColor: Colors.green,
                buttonColor: Colors.green,
                onButtonPressed: () {
                  setState(() {
                    _isDeductionDialogOpen = false;
                    _currentScanRecord = null;
                  });
                  Navigator.of(context).pop();
                },
              );
            }
            break;

          case ShowClearConfirmationState():
            _showClearConfirmationDialogAsync(context);
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return CustomScaffold(
            title: context.multiLanguage.scanPageTitle,
            backgroundColor: AppColors.scaffoldBackground,
            user: widget.user,
            showHomeIcon: true,
            currentIndex: 1,
            actions: [
              ScannerControls(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => context.read<ScanBloc>().add(ClearScannedItems()),
              ),
            ],
          body: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                debugPrint("QR DEBUG: Key pressed: ${event.logicalKey.keyId}");
                if (KeycodeConstants.scannerKeyCodes.contains(event.logicalKey.keyId)) {
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
                BlocBuilder<CameraBloc, CameraState>(
                  builder: (context, cameraState) {
                    final cameraBloc = context.read<CameraBloc>();
                    final controller = cameraBloc.scannerController;
                    final isActive = cameraState is CameraReady && cameraState.isActive;

                    return Container(
                      margin: const EdgeInsets.all(5),
                      child: QRScannerWidget(
                        controller: controller,
                        onDetect: (capture) {
                          cameraBloc.handleDetection(capture);
                        },
                        isActive: isActive,
                        onToggle: () {
                          context.read<CameraBloc>().add(
                            ToggleCamera(isActive: !isActive),
                          );
                        },
                      ),
                    );
                  },
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                                  context.multiLanguage.nameLabel,
                                  _currentScanRecord?.materialInfo['Material Name'] ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  context.multiLanguage.totalQuantityLabel,
                                  _currentScanRecord?.quantity ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  context.multiLanguage.deductionLabel,
                                  _currentScanRecord?.materialInfo['Deduction_QC2'] ?? '0',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  context.multiLanguage.dateLabel,
                                  _currentScanRecord?.materialInfo['Receipt Date'] ?? '',
                                ),
                                _buildDivider(),
                                _buildTableRow(
                                  context.multiLanguage.supplierLabel,
                                  _currentScanRecord?.materialInfo['Supplier'] ?? '',
                                ),
                                _buildDivider(),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Center(
                            child: MediaQuery.of(context).viewInsets.bottom > 0
                              ? const SizedBox.shrink()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                        onPressed: _showDeductionDialogAsync,
                                        style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                          child: Text(
                                            context.multiLanguage.saveButton,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white
                                            ),
                                          ),
                                        ),

                                        if (widget.isSpecialFeature) ...[
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                optionFunction = optionFunction == 2 ? 1 : 2;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: optionFunction == 2 ? Colors.red : Colors.green.shade600,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              optionFunction == 2 ? context.multiLanguage.decreaseButton : context.multiLanguage.increaseButton,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          
                                        ],
                                      ],
                                    )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                value.isEmpty ? context.multiLanguage.noScanDataMessage : value,
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
    final result = await ConfirmationDialog.showAsync(
      context: context,
      title: context.multiLanguage.clearDataTitleUPCASE,
      message: context.multiLanguage.clearScannedDataConfirmMessage,
      showCancelButton: true,
      confirmText: context.multiLanguage.okButtonUPCASE,
      cancelText: context.multiLanguage.cancelButton,
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