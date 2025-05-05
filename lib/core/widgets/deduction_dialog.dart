import 'package:architecture_scan_app/core/localization/context_extension.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class DeductionDialog extends StatefulWidget {
  final String productName;
  final String productCode;
  final String currentQuantity;
  final List<String> selectedReasons;
  final List<String> availableReasons;
  final Function(double, List<String>) onConfirm;
  final VoidCallback onCancel;
  final int optionFunction;
  final UserEntity user;
  final bool isQC2;

  const DeductionDialog({
    super.key,
    required this.productName,
    required this.productCode,
    required this.currentQuantity,
    required this.onConfirm,
    required this.onCancel,
    required this.availableReasons,
    this.selectedReasons = const [],
    required this.optionFunction,
    required this.user,
    required this.isQC2,
  });

  @override
  State<DeductionDialog> createState() => _DeductionDialogState();
}

class _DeductionDialogState extends State<DeductionDialog> {
  final TextEditingController _deductionController = TextEditingController(text: '0');
  List<String> _selectedReasons = [];
  late final List<String> _oldReasons;
  
  @override
  void initState() {
    super.initState();
    _selectedReasons = List.from(widget.selectedReasons);
    _oldReasons = List.from(widget.selectedReasons);
  }

  @override
  void dispose() {
    _deductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Container(
            width: 320,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Text(
                    context.multiLanguage.deductionTitleUPCASE,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
          
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            TextSpan(
                              text: context.multiLanguage.productLabel,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: widget.productName),
                          ],
                        ),
                      ),
                      
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            TextSpan(
                              text: context.multiLanguage.codeLabel,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: widget.productCode),
                          ],
                        ),
                      ),
          
                      const SizedBox(height: 5),
          
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            TextSpan(
                              text: context.multiLanguage.currentQuantityLabel,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: widget.currentQuantity,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.multiLanguage.deductionLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(5)),
                              color: Colors.grey[300]
                            ),
                            child: TextField(
                              controller: _deductionController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.singleLineFormatter,
                              ],
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.only(left: 10)
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      _buildReasonsSection(widget.optionFunction, widget.isQC2),
                    ],
                  ),
                ),
          
                const SizedBox(height: 10),
          
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: widget.onCancel,
                        child: Container(
                          height: 50,
                          width: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCCCCCC),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: Center(
                            child: Text(
                              context.multiLanguage.cancelButtonUPCASE,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      InkWell(
                        onTap: () {
                          final deduction = double.tryParse(_deductionController.text) ?? 0;
                          widget.onConfirm(deduction, _selectedReasons);
                        },
                        child: Container(
                          height: 50,
                          width: 100,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: Center(
                            child: Text(
                              context.multiLanguage.confirmButtonUPCASE,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonsSection(int optionFunction, bool isQC2) {
    final isDecreaseMode = optionFunction == 2;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.multiLanguage.reasonsLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!(isQC2 && isDecreaseMode))
              TextButton.icon(
                onPressed: _showReasonsDialogAsync,
                icon: const Icon(Icons.edit, size: 16, color: Colors.redAccent),
                label: Text(
                  context.multiLanguage.selectButton,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
          ],
        ),
        Container(
          width: double.infinity,
          height: 70,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          constraints: const BoxConstraints(maxHeight: 100),
          child: _selectedReasons.isEmpty
              ? Center(
                  child: Text(
                    context.multiLanguage.noReasonsSelected,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: -10,
                    children: _selectedReasons.map((reason) {
                      final isOldReason = _oldReasons.contains(reason);

                      if (isQC2) {
                        for (final reason in _oldReasons) {
                          if (!_selectedReasons.contains(reason)) {
                            _selectedReasons.add(reason);
                          }
                        }
                      }

                      if (isQC2 && isDecreaseMode) {
                        return Chip(
                          label: Text(reason),
                          labelStyle: const TextStyle(fontSize: 12),
                        );
                      }

                      if (isQC2 && !isDecreaseMode) {
                        return Chip(
                          label: Text(reason),
                          labelStyle: const TextStyle(fontSize: 12),
                          onDeleted: isOldReason
                              ? null
                              : () {
                                  setState(() {
                                    _selectedReasons.remove(reason);
                                  });
                                },
                          deleteIcon: isOldReason ? null : const Icon(Icons.close, size: 14),
                          deleteIconColor: Colors.redAccent,
                        );
                      }

                      return Chip(
                        label: Text(reason),
                        labelStyle: const TextStyle(fontSize: 12),
                        onDeleted: () {
                          setState(() {
                            _selectedReasons.remove(reason);
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 14),
                        deleteIconColor: Colors.redAccent,
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showReasonsDialogAsync() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => _buildReasonsDialog(dialogContext, widget.availableReasons, _selectedReasons),
    );

    if (result != null) {
      setState(() {
        _selectedReasons = result;
      });
    }
  }
  
  Widget _buildReasonsDialog(BuildContext context, List<String> availableReasons, List<String> initialSelected) {
    List<String> tempSelectedReasons = List.from(initialSelected);
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double maxDialogHeight = deviceHeight * 0.5;

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.multiLanguage.selectReasonsTitleUPCASE,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.evenRowColor,
        content: SizedBox(
          width: double.maxFinite,
          height: maxDialogHeight,
          child: availableReasons.isEmpty
              ? Center(child: Text(context.multiLanguage.noReasonsAvailableMessage))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableReasons.length,
                  itemBuilder: (context, index) {
                    final reason = availableReasons[index];
                    final isSelected = tempSelectedReasons.contains(reason);
                    final isOldReason = _oldReasons.contains(reason);
                    final isDisabled = widget.isQC2 && isOldReason;

                    return CheckboxListTile(
                      title: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDisabled ? Colors.grey : Colors.black
                        ),
                      ),
                      value: isSelected,
                      activeColor: isDisabled ? Colors.grey : AppColors.success,
                      onChanged: isDisabled ? null : (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelectedReasons.add(reason);
                          } else {
                            tempSelectedReasons.remove(reason);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, tempSelectedReasons);
            },
            child: Text(context.multiLanguage.okButtonUPCASE,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)
            ),
          ),
        ],
      ),
    );
  }
}