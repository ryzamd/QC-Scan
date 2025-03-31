// lib/features/process/presentation/bloc/processing_event.dart
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:equatable/equatable.dart';

abstract class ProcessingEvent extends Equatable {
  const ProcessingEvent();

  @override
  List<Object> get props => [];
}

class GetProcessingItemsEvent extends ProcessingEvent {}

class RefreshProcessingItemsEvent extends ProcessingEvent {}

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

// Thêm event mới để cập nhật status của item
class UpdateItemStatusEvent extends ProcessingEvent {
  final ProcessingItemEntity item;
  final SignalStatus newStatus;

  const UpdateItemStatusEvent({
    required this.item,
    required this.newStatus,
  });

  @override
  List<Object> get props => [item, newStatus];
}