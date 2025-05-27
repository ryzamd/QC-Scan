import 'dart:async';

import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/update_qc2_quantity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/get_processing_items.dart';
import '../../../../core/network/network_infor.dart';
import '../../../../core/services/get_translate_key.dart';
import 'processing_event.dart';
import 'processing_state.dart';

class ProcessingBloc extends Bloc<ProcessingEvent, ProcessingState> {
  final GetProcessingItems getProcessingItems;
  final UpdateQC2Quantity updateQC2Quantity;
  final NetworkInfo networkInfo;
  
  static const int MAX_CACHED_ITEMS = 100;

  String _lastQuery = '';
  List<ProcessingItemEntity>? _lastItems;
  List<ProcessingItemEntity>? _cachedFilteredItems;
  DateTime _lastCacheTime = DateTime.now();

  ProcessingBloc({
    required this.getProcessingItems,
    required this.updateQC2Quantity,
    required this.networkInfo,
  }) : super(ProcessingInitial()) {
    on<GetProcessingItemsEvent>(_onGetProcessingItemsAsync);
    on<RefreshProcessingItemsEvent>(_onRefreshProcessingItemsAsync);
    on<SortProcessingItemsEvent>(_onSortProcessingItemsAsync);
    on<SearchProcessingItemsEvent>(_onSearchProcessingItemsAsync);
    on<UpdateQC2QuantityEvent>(_onUpdateQC2QuantityAsync);
    on<SelectDateEvent>(_onSelectDateAsync);
  }

  @override
  Future<void> close() {
    _clearCache();
    return super.close();
  }

  void _clearCache() {
    _lastItems = null;
    _cachedFilteredItems = null;
  }

  void _limitCacheSize() {
    final now = DateTime.now();
    if (now.difference(_lastCacheTime).inMinutes > 5) {
      _clearCache();
      _lastCacheTime = now;
      return;
    }

    if (_lastItems != null && _lastItems!.length > MAX_CACHED_ITEMS) {
      _lastItems = _lastItems!.sublist(0, MAX_CACHED_ITEMS);
    }
    
    if (_cachedFilteredItems != null && _cachedFilteredItems!.length > MAX_CACHED_ITEMS) {
      _cachedFilteredItems = _cachedFilteredItems!.sublist(0, MAX_CACHED_ITEMS);
    }
  }

  Future<void> _onGetProcessingItemsAsync(GetProcessingItemsEvent event, Emitter<ProcessingState> emit) async {
    emit(ProcessingLoading());

    if (!await networkInfo.isConnected) {
      emit(ProcessingError(message: StringKey.networkErrorMessage));
      return;
    }

    try {
      final result = await getProcessingItems(
        GetProcessingParams(date: event.date),
      );

      await result.fold(
        (failure) async => emit(ProcessingError(message: failure.message)),
        (items) async {

          _lastItems = items;
          
          List<ProcessingItemEntity> sortedItems;
          if (items.length > 100) {
            sortedItems = await compute(_sortItemsByTimestamp,
                [List<ProcessingItemEntity>.from(items), true]);
          } else {
            sortedItems = List<ProcessingItemEntity>.from(items);
            _sortByTimestampAsync(sortedItems, true);
          }

          emit(ProcessingLoaded(
            items: items,
            filteredItems: sortedItems,
            sortColumn: 'timestamp',
            ascending: false,
            selectedDate: DateTime.now(),
          ));

          _limitCacheSize();
        },
      );
    } catch (e) {
      emit(ProcessingError(message: StringKey.errorLoadingDataMessage));
    }
  }

  Future<void> _onRefreshProcessingItemsAsync(RefreshProcessingItemsEvent event, Emitter<ProcessingState> emit) async {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      final existingItems = List<ProcessingItemEntity>.from(currentState.items);
      emit(ProcessingRefreshing(items: existingItems));

      if (!await networkInfo.isConnected) {
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
        emit(ProcessingError(message: StringKey.networkErrorMessage));
        return;
      }

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
              _sortItemsAsync(
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
          emit(ProcessingError(message: StringKey.errorLoadingDataMessage));
        }
      }
    } else {
      add(GetProcessingItemsEvent(date: event.date));
    }
  }

  Future<void> _onSortProcessingItemsAsync(SortProcessingItemsEvent event, Emitter<ProcessingState> emit) async {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      final sortColumn = event.column;
      final ascending = sortColumn == currentState.sortColumn
          ? !currentState.ascending
          : event.ascending;

      final itemsToSort = List<ProcessingItemEntity>.from(currentState.filteredItems);
      
      _sortItemsAsync(itemsToSort, sortColumn, ascending);

      emit(
        currentState.copyWith(
          filteredItems: itemsToSort,
          sortColumn: sortColumn,
          ascending: ascending,
        ),
      );
    }
  }

  Future<void> _onSearchProcessingItemsAsync(SearchProcessingItemsEvent event, Emitter<ProcessingState> emit) async {
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
        filteredItems = await compute(
          _filterItemsStatic,
          [currentState.items, query],
        );
        
        _sortItemsAsync(
          filteredItems,
          currentState.sortColumn,
          currentState.ascending,
        );
      } else {
        filteredItems = _filterItemsSync(currentState.items, query);
        _sortItemsAsync(
          filteredItems,
          currentState.sortColumn,
          currentState.ascending,
        );
      }

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

  Future<void> _onUpdateQC2QuantityAsync(UpdateQC2QuantityEvent event, Emitter<ProcessingState> emit) async {
    final currentState = state;

    if (currentState is ProcessingLoaded) {
      try {
        final targetItem = currentState.items.firstWhere(
          (item) => item.code == event.code,
          orElse: () => throw ServerFailure(StringKey.itemNotFound),
        );

        emit(ProcessingUpdatingState(item: targetItem));

        final result = await updateQC2Quantity(
          UpdateQC2QuantityParams(
            code: event.code,
            userName: event.userName,
            deduction: event.deduction,
            currentQuantity: event.currentQuantity,
            optionFunction: event.optionFunction,
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
                message: '${StringKey.deductionSuccessMessage}: ${event.deduction}',
              ),
            );
          },
        );
      } catch (e) {
        emit(ProcessingError(message: e.toString()));
      }
    }
  }

  Future<void> _sortByTimestampAsync(List<ProcessingItemEntity> items, bool ascending) async {
    items.sort((a, b) {
      return ascending
          ? a.cDate!.compareTo(b.cDate!)
          : b.cDate!.compareTo(a.cDate!);
    });
  }
  
  Future<void> _sortItemsAsync(List<ProcessingItemEntity> items, String column, bool ascending,
  ) async {
    if (column == 'timestamp') {
      _sortByTimestampAsync(items, ascending);
    }
  }
  
  List<ProcessingItemEntity> _filterItemsSync(List<ProcessingItemEntity> items, String query) {
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

  Future<void> _onSelectDateAsync(SelectDateEvent event, Emitter<ProcessingState> emit) async {
    if (!await networkInfo.isConnected) {
      emit(ProcessingError(message: StringKey.networkErrorMessage));
      return;
    }
    
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

  Future<void> loadDataAsync() async {
    add(GetProcessingItemsEvent(date: formattedSelectedDate));
  }

  Future<void> refreshDataAsync() async {
    add(RefreshProcessingItemsEvent(date: formattedSelectedDate));
  }
}