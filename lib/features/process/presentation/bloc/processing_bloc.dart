import 'dart:async';

import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/update_qc2_quantity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/get_processing_items.dart';
import 'processing_event.dart';
import 'processing_state.dart';

class ProcessingBloc extends Bloc<ProcessingEvent, ProcessingState> {
  final GetProcessingItems getProcessingItems;
  final UpdateQC2Quantity updateQC2Quantity;
  
  // Cache for minimizing memory allocations during filtering
  String _lastQuery = '';
  List<ProcessingItemEntity>? _lastItems;
  List<ProcessingItemEntity>? _cachedFilteredItems;

  ProcessingBloc({
    required this.getProcessingItems,
    required this.updateQC2Quantity,
  }) : super(ProcessingInitial()) {
    on<GetProcessingItemsEvent>(_onGetProcessingItems);
    on<RefreshProcessingItemsEvent>(_onRefreshProcessingItems);
    on<SortProcessingItemsEvent>(_onSortProcessingItems);
    on<SearchProcessingItemsEvent>(_onSearchProcessingItems);
    on<UpdateQC2QuantityEvent>(_onUpdateQC2Quantity);
    on<SelectDateEvent>(_onSelectDate);
  }

  Future<void> _onGetProcessingItems(
    GetProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    emit(ProcessingLoading());

    try {
      final result = await getProcessingItems(
        GetProcessingParams(date: event.date),
      );

      await result.fold( // <-- Add await here
        (failure) async => emit(ProcessingError(message: failure.message)),
        (items) async {

          _lastItems = items;
          
          List<ProcessingItemEntity> sortedItems;
          if (items.length > 100) {
            sortedItems = await compute(_sortItemsByTimestamp,
                [List<ProcessingItemEntity>.from(items), true]);
          } else {
            sortedItems = List<ProcessingItemEntity>.from(items);
            _sortByTimestamp(sortedItems, true);
          }

          emit(ProcessingLoaded(
            items: items,
            filteredItems: sortedItems,
            sortColumn: 'timestamp',
            ascending: true,
            selectedDate: DateTime.now(),
          ));
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
      final existingItems = List<ProcessingItemEntity>.from(currentState.items);
      emit(ProcessingRefreshing(items: existingItems));

      try {
        final result = await getProcessingItems(
          GetProcessingParams(date: event.date),
        );

        await result.fold(
          (failure) async {
            if (!emit.isDone) {
              emit(
                ProcessingLoaded(
                  items: existingItems,
                  filteredItems: existingItems,
                  sortColumn: currentState.sortColumn,
                  ascending: currentState.ascending,
                  searchQuery: currentState.searchQuery,
                  selectedDate: DateTime.now(),
                ),
              );
            }
            if (!emit.isDone) {
              emit(ProcessingError(message: failure.message));
            }
          },
          (items) async {
            _lastItems = items;
            
            List<ProcessingItemEntity> filteredItems;
            if (items.length > 100) {
              filteredItems = await compute(
                _filterAndSortItems,
                [
                  items,
                  currentState.searchQuery,
                  currentState.sortColumn,
                  currentState.ascending
                ],
              );
            } else {
              filteredItems = _filterItemsSync(items, currentState.searchQuery);
              _sortItems(
                filteredItems,
                currentState.sortColumn,
                currentState.ascending,
              );
            }
            
            _cachedFilteredItems = filteredItems;
            _lastQuery = currentState.searchQuery;

            if (!emit.isDone) {
              emit(
                ProcessingLoaded(
                  items: items,
                  filteredItems: filteredItems,
                  sortColumn: currentState.sortColumn,
                  ascending: currentState.ascending,
                  searchQuery: currentState.searchQuery,
                  selectedDate: DateTime.now(),
                ),
              );
            }
          },
        );
      } catch (e) {
        if (!emit.isDone) {
          emit(
            ProcessingLoaded(
              items: existingItems,
              filteredItems: existingItems,
              sortColumn: currentState.sortColumn,
              ascending: currentState.ascending,
              searchQuery: currentState.searchQuery,
              selectedDate: DateTime.now(),
            ),
          );
          emit(ProcessingError(message: 'Error refreshing data: ${e.toString()}'));
        }
      }
    } else {
      add(GetProcessingItemsEvent(date: event.date));
    }
  }

  Future<void> _onSortProcessingItems(
    SortProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      final sortColumn = event.column;
      final ascending = sortColumn == currentState.sortColumn
          ? !currentState.ascending
          : event.ascending;

      // Use cached items if possible
      final itemsToSort = List<ProcessingItemEntity>.from(currentState.filteredItems);
      
      // Sort directly for small lists
      _sortItems(itemsToSort, sortColumn, ascending);

      emit(
        currentState.copyWith(
          filteredItems: itemsToSort,
          sortColumn: sortColumn,
          ascending: ascending,
        ),
      );
    }
  }

  Future<void> _onSearchProcessingItems(
    SearchProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      final query = event.query;
      
      if (query == _lastQuery && _lastItems == currentState.items && _cachedFilteredItems != null) {
        emit(
          currentState.copyWith(
            filteredItems: _cachedFilteredItems,
            searchQuery: query,
          ),
        );
        return;
      }
      
      List<ProcessingItemEntity> filteredItems;
      if (currentState.items.length > 100) {
        // Use compute with static method
        filteredItems = await compute(
          _filterItemsStatic,
          [currentState.items, query],
        );
        
        _sortItems(
          filteredItems,
          currentState.sortColumn,
          currentState.ascending,
        );
      } else {
        // For small lists, process directly
        filteredItems = _filterItemsSync(currentState.items, query);
        _sortItems(
          filteredItems,
          currentState.sortColumn,
          currentState.ascending,
        );
      }

      // Cache the results
      _cachedFilteredItems = filteredItems;
      _lastQuery = query;

      emit(
        currentState.copyWith(
          filteredItems: filteredItems,
          searchQuery: query,
        ),
      );
    }
  }

  Future<void> _onUpdateQC2Quantity(
    UpdateQC2QuantityEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;

    if (currentState is ProcessingLoaded) {
      try {
        // Find target item
        final targetItem = currentState.items.firstWhere(
          (item) => item.code == event.code,
          orElse: () => throw ServerFailure('Item not found'),
        );

        // Emit processing state immediately
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
          (failure) async {
            emit(ProcessingError(message: failure.message));
          },
          (updatedItem) {
            emit(
              ProcessingUpdatedState(
                updatedItem: updatedItem,
                message: 'Deduction successful: ${event.deduction}',
              ),
            );
          },
        );
      } catch (e) {
        emit(ProcessingError(message: e.toString()));
      }
    }
  }

  // HELPER METHODS
  
  // Sort directly in this thread
  void _sortByTimestamp(List<ProcessingItemEntity> items, bool ascending) {
    items.sort((a, b) {
      return ascending
          ? a.cDate!.compareTo(b.cDate!)
          : b.cDate!.compareTo(a.cDate!);
    });
  }
  
  void _sortItems(
    List<ProcessingItemEntity> items,
    String column,
    bool ascending,
  ) {
    if (column == 'timestamp') {
      _sortByTimestamp(items, ascending);
    }
  }
  
  List<ProcessingItemEntity> _filterItemsSync(
    List<ProcessingItemEntity> items,
    String query,
  ) {
    if (query.isEmpty) {
      return List.from(items);
    }

    final lowercaseQuery = query.toLowerCase();

    return items.where((item) {
      return item.mName!.toLowerCase().contains(lowercaseQuery) ||
             item.mPrjcode!.toLowerCase().contains(lowercaseQuery) ||
             item.mQty.toString().contains(lowercaseQuery) ||
             item.mVendor!.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Static method for compute
  static List<ProcessingItemEntity> _filterItemsStatic(List<dynamic> params) {
    final items = params[0] as List<ProcessingItemEntity>;
    final query = params[1] as String;
    
    if (query.isEmpty) {
      return List.from(items);
    }

    final lowercaseQuery = query.toLowerCase();

    return items.where((item) {
      return item.mName!.toLowerCase().contains(lowercaseQuery) ||
             item.mPrjcode!.toLowerCase().contains(lowercaseQuery) ||
             item.mQty.toString().contains(lowercaseQuery) ||
             item.mVendor!.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  // STATIC METHODS FOR COMPUTE
  
  // For background compute
  static List<ProcessingItemEntity> _sortItemsByTimestamp(List<dynamic> params) {
    final items = params[0] as List<ProcessingItemEntity>;
    final ascending = params[1] as bool;
    
    items.sort((a, b) {
      return ascending
          ? a.cDate!.compareTo(b.cDate!)
          : b.cDate!.compareTo(a.cDate!);
    });
    
    return items;
  }
  
  // Static methods for compute
  static List<ProcessingItemEntity> _filterAndSortItems(List<dynamic> params) {
    final items = params[0] as List<ProcessingItemEntity>;
    final query = params[1] as String;
    final sortColumn = params[2] as String;
    final ascending = params[3] as bool;
    
    List<ProcessingItemEntity> result;
    if (query.isEmpty) {
      result = List.from(items);
    } else {
      final lowercaseQuery = query.toLowerCase();
      result = items.where((item) {
        return item.mName!.toLowerCase().contains(lowercaseQuery) ||
               item.mPrjcode!.toLowerCase().contains(lowercaseQuery) ||
               item.mQty.toString().contains(lowercaseQuery) ||
               item.mVendor!.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    
    if (sortColumn == 'timestamp') {
      result.sort((a, b) {
        return ascending
            ? a.cDate!.compareTo(b.cDate!)
            : b.cDate!.compareTo(a.cDate!);
      });
    }
    
    return result;
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 00:00:00';
  }

  Future<void> _onSelectDate(
    SelectDateEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is ProcessingLoaded) {
      emit(currentState.copyWith(selectedDate: event.selectedDate));
      add(RefreshProcessingItemsEvent(date: _formatDateForApi(event.selectedDate)));
    } else {
      add(GetProcessingItemsEvent(date: _formatDateForApi(event.selectedDate)));
    }
  }

  String get formattedSelectedDate {
    if (state is ProcessingLoaded) {
      final date = (state as ProcessingLoaded).selectedDate;
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 00:00:00';
    }
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 00:00:00';
  }

  void loadData() {
    add(GetProcessingItemsEvent(date: formattedSelectedDate));
  }

  void refreshData() {
    add(RefreshProcessingItemsEvent(date: formattedSelectedDate));
  }
}