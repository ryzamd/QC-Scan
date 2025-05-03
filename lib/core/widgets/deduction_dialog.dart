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

  const DeductionDialog({
    super.key,
    required this.productName,
    required this.productCode,
    required this.currentQuantity,
    required this.onConfirm,
    required this.onCancel,
    required this.availableReasons,
    this.selectedReasons = const [],
  });

  @override
  State<DeductionDialog> createState() => _DeductionDialogState();
}

class _DeductionDialogState extends State<DeductionDialog> {
  final TextEditingController _deductionController = TextEditingController(text: '0');
  List<String> _selectedReasons = [];
  
  @override
  void initState() {
    super.initState();
    _selectedReasons = List.from(widget.selectedReasons);
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
                  child: const Text(
                    'DEDUCTION',
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
                            const TextSpan(
                              text: 'Product: ',
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
                            const TextSpan(
                              text: 'Code: ',
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
                            const TextSpan(
                              text: 'Current Quantity: ',
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
                          const Text(
                            'Deduction',
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
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.only(left: 10)
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      _buildReasonsSection(),
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
                          child: const Center(
                            child: Text(
                              'CANCEL',
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
                          child: const Center(
                            child: Text(
                              'CONFIRM',
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

  Widget _buildReasonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reasons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _showReasonsDialogAsync,
              icon: const Icon(Icons.edit, size: 16, color: Colors.redAccent,),
              label: const Text('Select', style: TextStyle(color: Colors.redAccent),),
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
            ? const Center(
                child: Text(
                    'No reasons selected',
                    style: TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
              ),
            )
            : SingleChildScrollView(
                child: Wrap(
                  spacing: 4,
                  runSpacing: -10 ,
                  children: _selectedReasons.map((reason) {
                    return Chip(
                      label: Text(reason),
                      labelStyle: const TextStyle(fontSize: 12),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: Colors.redAccent,
                      onDeleted: () {
                        setState(() {
                          _selectedReasons.remove(reason);
                        });
                      },
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
        title: const Text('SELECT REASONS',
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
              ? const Center(child: Text('No reasons available'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableReasons.length,
                  itemBuilder: (context, index) {
                    final reason = availableReasons[index];
                    final isSelected = tempSelectedReasons.contains(reason);

                    return CheckboxListTile(
                      title: Text(reason, style: TextStyle(fontSize: 16),),
                      value: isSelected,
                      activeColor: AppColors.success,
                      onChanged: (bool? value) {
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
            child: const Text('OK',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)
            ),
          ),
        ],
      ),
    );
  }
}