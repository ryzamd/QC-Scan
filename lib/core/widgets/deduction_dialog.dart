// lib/core/widgets/deduction_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeductionDialog extends StatefulWidget {
  final String productName;
  final String productCode;
  final String currentQuantity;
  final Function(double) onConfirm;
  final VoidCallback onCancel;

  const DeductionDialog({
    super.key,
    required this.productName,
    required this.productCode,
    required this.currentQuantity,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<DeductionDialog> createState() => _DeductionDialogState();
}

class _DeductionDialogState extends State<DeductionDialog> {
  final TextEditingController _deductionController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
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
        borderRadius: BorderRadius.circular(12),
      ),
      content: Container(
        width: 320,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 5,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                  'DEDUCTION',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
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
                  
                  // Product code
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

                  // Current quantity
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'Current Quantity: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: widget.currentQuantity, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // Deduction input
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
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: Colors.grey[300]
                        ),
                        child: TextField(
                        controller: _deductionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left: 10)
                        ),
                        // onChanged: (value) {
                        //   _updateRemainingQuantity();
                        // },
                      ),
                      )
                    ],
                  ),
                 
                  // Remaining
                  // Container(
                  //   padding: const EdgeInsets.only(top: 10),
                  //   child: Row(
                  //     children: [
                  //       const Text(
                  //         'Remaining: ',
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       Text(
                  //         '$_remainingQuantity',
                  //         style: const TextStyle(
                  //           color: Colors.redAccent,
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel button
                  InkWell(
                      onTap: widget.onCancel,
                      child: Container(
                        height: 50,
                        width: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCCCCCC),
                          borderRadius: BorderRadius.all( Radius.circular(5)),
                        ),
                        child: const Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Confirm button
                  InkWell(
                      onTap: () {
                        final deduction = double.tryParse(_deductionController.text) ?? 0;
                        widget.onConfirm(deduction);
                      },
                      child: Container(
                        height: 50,
                        width: 100,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all( Radius.circular(5)),
                        ),
                        child: const Center(
                          child: Text(
                            'CONFIRM',
                            style: TextStyle(
                              fontSize: 16,
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
           SizedBox(height: 12)
          ],
        ),
      ),
    );
  }
}