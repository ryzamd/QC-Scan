import 'package:equatable/equatable.dart';

abstract class ProcessingEvent extends Equatable {
  const ProcessingEvent();

  @override
  List<Object> get props => [];
}

class GetProcessingItemsEvent extends ProcessingEvent {
  final String userName;
  
  const GetProcessingItemsEvent({required this.userName});
  
  @override
  List<Object> get props => [userName];
}

class RefreshProcessingItemsEvent extends ProcessingEvent {
  final String userName;
  
  const RefreshProcessingItemsEvent({required this.userName});
  
  @override
  List<Object> get props => [userName];
}

class SortProcessingItemsEvent extends ProcessingEvent {
  final String column;
  final bool ascending;

  const SortProcessingItemsEvent({
    required this.column,
    required this.ascending,
  });

  @override
  List<Object> get props => [column, ascending];
}

class SearchProcessingItemsEvent extends ProcessingEvent {
  final String query;

  const SearchProcessingItemsEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class UpdateQC2QuantityEvent extends ProcessingEvent {
  final String code;
  final String userName;
  final double deduction;
  final double currentQuantity;

  const UpdateQC2QuantityEvent({
    required this.code,
    required this.userName,
    required this.deduction,
    required this.currentQuantity,
  });

  @override
  List<Object> get props => [code, userName, deduction, currentQuantity];
}