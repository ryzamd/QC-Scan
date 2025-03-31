import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:equatable/equatable.dart';

class ProcessingItemEntity extends Equatable {
  final String itemName;
  final String orderNumber;
  final int quantity;
  final int exception;
  final String timestamp;
  final SignalStatus status;

  const ProcessingItemEntity({
    required this.itemName,
    required this.orderNumber,
    required this.quantity,
    required this.exception,
    required this.timestamp,
    required this.status,
  });

  @override
  List<Object?> get props => [
    itemName,
    orderNumber,
    quantity,
    exception,
    timestamp,
    status,
  ];
}