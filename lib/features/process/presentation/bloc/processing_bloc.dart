import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/update_qc2_quantity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/get_processing_items.dart';
import 'processing_event.dart';
import 'processing_state.dart';

class ProcessingBloc extends Bloc<ProcessingEvent, ProcessingState> {
  final GetProcessingItems getProcessingItems;
  final UpdateQC2Quantity updateQC2Quantity;

  ProcessingBloc({
    required this.getProcessingItems,
    required this.updateQC2Quantity,
  }) : super(ProcessingInitial()) {
    on<GetProcessingItemsEvent>(_onGetProcessingItems);
    on<RefreshProcessingItemsEvent>(_onRefreshProcessingItems);
    on<SortProcessingItemsEvent>(_onSortProcessingItems);
    on<SearchProcessingItemsEvent>(_onSearchProcessingItems);
    on<UpdateQC2QuantityEvent>(_onUpdateQC2Quantity);
  }

  Future<void> _onGetProcessingItems(
    GetProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    emit(ProcessingLoading());

    try {
      final result = await getProcessingItems(
        GetProcessingParams(userName: event.userName),
      );

      result.fold(
        (failure) => emit(ProcessingError(message: failure.message)),
        (items) {
          // Default sort by status
          final sortedItems = List<ProcessingItemEntity>.from(items);
          _sortItemsByStatus(sortedItems, true);

          emit(
            ProcessingLoaded(
              items: items,
              filteredItems: sortedItems,
              sortColumn: 'status',
              ascending: true,
            ),
          );
        },
      );
    } catch (e) {
      emit(ProcessingError(message: 'Error loading data: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshProcessingItems(
    RefreshProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      // Keep current state to avoid UI flashing
      final existingItems = List<ProcessingItemEntity>.from(currentState.items);

      emit(ProcessingRefreshing(items: existingItems));

      try {
        final result = await getProcessingItems(
          GetProcessingParams(userName: event.userName),
        );

        result.fold(
          (failure) {
            // If API fails, keep current data
            emit(
              ProcessingLoaded(
                items: existingItems,
                filteredItems: _filterItems(
                  existingItems,
                  currentState.searchQuery,
                ),
                sortColumn: currentState.sortColumn,
                ascending: currentState.ascending,
                searchQuery: currentState.searchQuery,
              ),
            );

            // Show error
            emit(ProcessingError(message: failure.message));
          },
          (items) {
            // Apply current filters and sorting
            final filteredItems = _filterItems(items, currentState.searchQuery);
            _sortItems(
              filteredItems,
              currentState.sortColumn,
              currentState.ascending,
            );

            emit(
              ProcessingLoaded(
                items: items,
                filteredItems: filteredItems,
                sortColumn: currentState.sortColumn,
                ascending: currentState.ascending,
                searchQuery: currentState.searchQuery,
              ),
            );
          },
        );
      } catch (e) {
        // Handle errors and keep current data
        emit(
          ProcessingLoaded(
            items: existingItems,
            filteredItems: _filterItems(
              existingItems,
              currentState.searchQuery,
            ),
            sortColumn: currentState.sortColumn,
            ascending: currentState.ascending,
            searchQuery: currentState.searchQuery,
          ),
        );

        emit(
          ProcessingError(message: 'Error refreshing data: ${e.toString()}'),
        );
      }
    } else {
      // If not in loaded state, initiate a fresh load
      add(GetProcessingItemsEvent(userName: event.userName));
    }
  }

  void _onSortProcessingItems(
    SortProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      final sortedItems = List<ProcessingItemEntity>.from(
        currentState.filteredItems,
      );

      final sortColumn = event.column;
      final ascending =
          sortColumn == currentState.sortColumn
              ? !currentState.ascending
              : event.ascending;

      _sortItems(sortedItems, sortColumn, ascending);

      emit(
        currentState.copyWith(
          filteredItems: sortedItems,
          sortColumn: sortColumn,
          ascending: ascending,
        ),
      );
    }
  }

  void _onSearchProcessingItems(
    SearchProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      final filteredItems = _filterItems(currentState.items, event.query);

      _sortItems(
        filteredItems,
        currentState.sortColumn,
        currentState.ascending,
      );

      emit(
        currentState.copyWith(
          filteredItems: filteredItems,
          searchQuery: event.query,
        ),
      );
    }
  }

  // Helper methods for sorting and filtering
  void _sortItems(
    List<ProcessingItemEntity> items,
    String column,
    bool ascending,
  ) {
    if (column == 'status') {
      _sortItemsByStatus(items, ascending);
    } else if (column == 'timestamp') {
      _sortItemsByTimestamp(items, ascending);
    }
  }

  void _sortItemsByStatus(List<ProcessingItemEntity> items, bool ascending) {
    items.sort((a, b) {
      final aValue = a.status.index;
      final bValue = b.status.index;
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
  }

  void _sortItemsByTimestamp(List<ProcessingItemEntity> items, bool ascending) {
    items.sort((a, b) {
      return ascending
          ? a.cDate!.compareTo(b.cDate!)
          : b.cDate!.compareTo(a.cDate!);
    });
  }

  List<ProcessingItemEntity> _filterItems(
    List<ProcessingItemEntity> items,
    String query,
  ) {
    if (query.isEmpty) {
      return List.from(items);
    }

    final lowercaseQuery = query.toLowerCase();

    return items.where((item) {
      // Search by name and project code
      if (item.mName!.toLowerCase().contains(lowercaseQuery) ||
          item.mPrjcode!.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search by quantity
      if (item.mQty.toString().contains(lowercaseQuery)) {
        return true;
      }

      // Search by supplier
      if (item.mVendor!.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search by status
      if (lowercaseQuery == 'success' && item.status == SignalStatus.success) {
        return true;
      }
      if (lowercaseQuery == 'pending' && item.status == SignalStatus.pending) {
        return true;
      }
      if (lowercaseQuery == 'failed' && item.status == SignalStatus.failed) {
        return true;
      }

      return false;
    }).toList();
  }

  Future<void> _onUpdateQC2Quantity(
    UpdateQC2QuantityEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;

    if (currentState is ProcessingLoaded) {
      try {
        ProcessingItemEntity? targetItem = currentState.items.firstWhere(
          (item) => item.code == event.code,
          orElse: () => throw ServerFailure('Item not found'),
        );

        emit(ProcessingUpdatingState(item: targetItem));

        final result = await updateQC2Quantity(
          UpdateQC2QuantityParams(
            code: event.code,
            userName: event.userName,
            deduction: event.deduction,
            currentQuantity: event.currentQuantity,
          ),
        );

        result.fold(
          (failure) {
            emit(currentState);
            emit(ProcessingError(message: failure.message));
          },
          (updatedItem) {
            final updatedItems = List<ProcessingItemEntity>.from(
              currentState.items,
            );
            final index = updatedItems.indexWhere(
              (item) => item.code == updatedItem.code,
            );

            if (index != -1) {
              updatedItems[index] = updatedItem;
            }

            emit(currentState.copyWith(items: updatedItems));

            emit(
              ProcessingUpdatedState(
                updatedItem: updatedItem,
                message: 'Deduction successful: ${event.deduction}',
              ),
            );
          },
        );
      } catch (e) {
        emit(currentState);
        emit(ProcessingError(message: e.toString()));
      }
    }
  }
}
