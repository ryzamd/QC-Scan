// lib/features/scan/presentation/widgets/scan_widgets.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../../../../core/constants/app_colors.dart';

/// Improved QR Scanner Widget
class QRScannerWidget extends StatelessWidget {
  final MobileScannerController? controller;
  final Function(BarcodeCapture)? onDetect;
  final bool isActive;
  final VoidCallback onToggle;
  
  const QRScannerWidget({
    super.key,
    required this.controller,
    required this.onDetect,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Reduce debug logging in production
    if (kDebugMode) {
      debugPrint("Building QRScannerWidget, camera active: $isActive");
    }
    
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            // Only build camera widget when active to save resources
            child: isActive && controller != null
              ? MobileScanner(
                  controller: controller!,
                  onDetect: (barcodes) {
                    // Move processing to compute for heavy barcodes
                    if (barcodes.barcodes.isNotEmpty) {
                      onDetect?.call(barcodes);
                    }
                  },
                  // Optimize error recovery
                  errorBuilder: _buildErrorWidget,
                )
              : const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      "Camera is off",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          ),
        ),
        
        // Only build overlay when needed
        if (isActive) _buildScanOverlay(),
      ],
    );
  }
  
  // Extract widget building to methods to improve readability and performance
  Widget _buildErrorWidget(BuildContext context, MobileScannerException error, Widget? child) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            Text(
              "Camera error: ${error.errorCode}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: const WidgetStatePropertyAll(Color(0xFFFF9D23)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ))
              ),
              onPressed: () {
                controller!.stop();
                controller!.start();
              },
              child: const Text("Try Again", 
                style: TextStyle(color: Color(0xFFFEF9E1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScanOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          margin: const EdgeInsets.all(5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCorner(true, true),
                  _buildCorner(true, false),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCorner(false, true),
                  _buildCorner(false, false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  
  // Function to build a corner for the scanning frame
  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.redAccent, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.redAccent, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.redAccent, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.redAccent, width: 4) : BorderSide.none,
        ),
      ),
    );
  }


/// Information row widget for material details
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelBgColor;
  final Color valueBgColor;
  
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelBgColor = Colors.blue,
    this.valueBgColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [labelBgColor, labelBgColor.withValues(alpha:  0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          // Value with better styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Text(
              value.isEmpty ? 'No data available' : value,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Save Button Widget
class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  
  const SaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 3,
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
              'SAVE DATA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
      ),
    );
  }
}

/// Scanner Controls with BLoC integration
class ScannerControls extends StatelessWidget {
  const ScannerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanBloc, ScanState>(
      buildWhen: (previous, current) {
        return current is ScanningState || current is MaterialInfoLoaded;
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
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isTorchEnabled ? Icons.flash_on : Icons.flash_off,
                color: isTorchEnabled ? Colors.yellow : Colors.grey,
              ),
              onPressed: isCameraActive 
                ? () => context.read<ScanBloc>().add(ToggleTorch(!isTorchEnabled))
                : null,
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: isCameraActive 
                ? () => context.read<ScanBloc>().add(SwitchCamera())
                : null,
            ),
            IconButton(
              icon: Icon(
                isCameraActive ? Icons.stop : Icons.play_arrow,
                color: isCameraActive ? Colors.red : Colors.green,
              ),
              onPressed: () => context.read<ScanBloc>().add(ToggleCamera(!isCameraActive)),
            ),
          ],
        );
      },
    );
  }
}

/// Scanned Items Table with BLoC integration
class ScannedItemsTable extends StatelessWidget {
  const ScannedItemsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanBloc, ScanState>(
      buildWhen: (previous, current) {
        return current is ScanningState || current is MaterialInfoLoaded || 
               current is DataSavedState;
      },
      builder: (context, state) {
        List<List<String>> scannedItems = [];
        
        if (state is ScanningState) {
          scannedItems = state.scannedItems;
        } else if (state is MaterialInfoLoaded) {
          scannedItems = state.scannedItems;
        } else if (state is DataSavedState) {
          scannedItems = state.scannedItems;
        }
        
        return Container(
          height: 150, // Fixed height for the scanned items table
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:  0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              Expanded(
                child: scannedItems.isEmpty
                  ? const Center(child: Text("No scanned items"))
                  : ListView.builder(
                      itemCount: scannedItems.length,
                      itemBuilder: (context, index) {
                        return _buildTableRow(scannedItems[index]);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              "Code",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "Status",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "Quantity",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(List<String> rowData) {
    Color statusColor = Colors.orange;
    if (rowData.length > 1) {
      if (rowData[1] == 'Scanned') { statusColor = Colors.green;}
      else if (rowData[1] == 'Processing') {statusColor = Colors.blue;}
      else if (rowData[1] == 'Error') {statusColor = Colors.red;}
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              rowData[0],
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              rowData.length > 1 ? rowData[1] : "Processing",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              rowData.length > 2 ? rowData[2] : "1",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Material Info Section Widget with BLoC integration
class MaterialInfoSection extends StatelessWidget {
  const MaterialInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanBloc, ScanState>(
      buildWhen: (previous, current) {
        return current is MaterialInfoLoaded || current is SavingDataState;
      },
      builder: (context, state) {
        if (state is MaterialInfoLoaded || state is SavingDataState) {
          Map<String, String> materialInfo = {};
          String currentBarcode = '';
          bool isSaving = false;
          
          if (state is MaterialInfoLoaded) {
            materialInfo = state.materialInfo;
            currentBarcode = state.currentBarcode;
          } else if (state is SavingDataState) {
            materialInfo = state.materialInfo;
            currentBarcode = state.currentBarcode;
            isSaving = true;
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material info title with card-like appearance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:  0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Material Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Material info cards
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: materialInfo.entries.map((entry) {
                    return InfoRow(
                      label: entry.key,
                      value: entry.value,
                      labelBgColor: AppColors.primary,
                      valueBgColor: Colors.grey.shade600,
                    );
                  }).toList(),
                ),
              ),
              
              // Save button
              Center(
                child: SaveButton(
                  onPressed: () {
                    context.read<ScanBloc>().add(SaveScannedData(
                      barcode: currentBarcode,
                      quantity: materialInfo['Quantity'] ?? '1',
                      materialInfo: materialInfo,
                      userId: context.read<ScanBloc>().currentUser.userId,
                    ));
                  },
                  isLoading: isSaving,
                ),
              ),
            ],
          );
        }
        
        return const Center(
          child: Text('No material information available'),
        );
      },
    );
  }
}

/// Scanned Items Section Widget with BLoC integration
class ScannedItemsSection extends StatelessWidget {
  const ScannedItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanBloc, ScanState>(
      buildWhen: (previous, current) {
        return current is ScanningState || current is MaterialInfoLoaded || 
               current is DataSavedState;
      },
      builder: (context, state) {
        List<List<String>> scannedItems = [];
        
        if (state is ScanningState) {
          scannedItems = state.scannedItems;
        } else if (state is MaterialInfoLoaded) {
          scannedItems = state.scannedItems;
        } else if (state is DataSavedState) {
          scannedItems = state.scannedItems;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scanned Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: ${scannedItems.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ScannedItemsTable(),
          ],
        );
      },
    );
  }
}

/// Widget for QR scanning area
class QRScanSection extends StatelessWidget {
  const QRScanSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanBloc, ScanState>(
      buildWhen: (previous, current) {
        return current is ScanningState || current is MaterialInfoLoaded;
      },
      builder: (context, state) {
        bool isActive = false;
        MobileScannerController? controller;
        
        if (state is ScanningState) {
          isActive = state.isCameraActive;
          controller = state.controller;
        } else if (state is MaterialInfoLoaded) {
          isActive = state.isCameraActive;
          controller = state.controller;
        }
        
        return Container(
          height: 160,
          width: double.infinity,
          margin: const EdgeInsets.all(5),
          child: QRScannerWidget(
            controller: controller,
            onDetect: (barcodes) {
              if (barcodes.barcodes.isNotEmpty) {
                final barcode = barcodes.barcodes.first;
                if (barcode.rawValue != null) {
                  context.read<ScanBloc>().add(BarcodeDetected(barcode.rawValue!));
                }
              }
            },
            isActive: isActive,
            onToggle: () {
              context.read<ScanBloc>().add(ToggleCamera(!isActive));
            },
          ),
        );
      },
    );
  }
}