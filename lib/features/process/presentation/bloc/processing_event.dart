import 'package:equatable/equatable.dart';

abstract class ProcessingEvent extends Equatable {
  const ProcessingEvent();

  @override
  List<Object> get props => [];
}

class GetProcessingItemsEvent extends ProcessingEvent {
  final String date;
  
  const GetProcessingItemsEvent({required this.date});
  
  @override
  List<Object> get props => [date];
}

class RefreshProcessingItemsEvent extends ProcessingEvent {
  final String date;
  
  const RefreshProcessingItemsEvent({required this.date});
  
  @override
  List<Object> get props => [date];
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
  final int optionFunction;

  const UpdateQC2QuantityEvent({
    required this.code,
    required this.userName,
    required this.deduction,
    required this.currentQuantity,
    required this.optionFunction,
  });

  @override
  List<Object> get props => [code, userName, deduction, currentQuantity, optionFunction];
}

class SelectDateEvent extends ProcessingEvent {
  final DateTime selectedDate;
  
  const SelectDateEvent({required this.selectedDate});
  
  @override
  List<Object> get props => [selectedDate];
}