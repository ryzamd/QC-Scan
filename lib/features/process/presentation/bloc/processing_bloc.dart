// lib/features/process/presentation/bloc/processing_bloc.dart
import 'package:architecture_scan_app/core/di/dependencies.dart' as di;
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:architecture_scan_app/core/services/processing_data_service.dart';
import 'package:architecture_scan_app/features/process/data/models/processing_item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/get_processing_items.dart'
    as get_process;
import 'package:architecture_scan_app/features/process/domain/usecases/refresh_processing_items.dart';
import 'processing_event.dart';
import 'processing_state.dart';

class ProcessingBloc extends Bloc<ProcessingEvent, ProcessingState> {
  final get_process.GetProcessingItems getProcessingItems;
  final RefreshProcessingItems refreshProcessingItems;

  ProcessingBloc({
    required this.getProcessingItems,
    required this.refreshProcessingItems,
  }) : super(ProcessingInitial()) {
    on<GetProcessingItemsEvent>(_onGetProcessingItems);
    on<RefreshProcessingItemsEvent>(_onRefreshProcessingItems);
    on<SortProcessingItemsEvent>(_onSortProcessingItems);
    on<SearchProcessingItemsEvent>(_onSearchProcessingItems);
    on<UpdateItemStatusEvent>(
      _onUpdateItemStatus,
    ); // Thêm handler cho event mới
  }

  Future<void> _onGetProcessingItems(
    GetProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    emit(ProcessingLoading());

    try {
      final result = await getProcessingItems(get_process.NoParams());

      result.fold(
        (failure) => emit(ProcessingError(message: failure.message)),
        (apiItems) {
          // Thêm dữ liệu từ service
          final serviceItems = di.sl<ProcessingDataService>().getAllItems();

          // Kết hợp tất cả các nguồn dữ liệu
          final allItems = [...apiItems, ...serviceItems];

          // Loại bỏ trùng lặp
          final processedItems = <String, ProcessingItemEntity>{};

          for (final item in allItems) {
            final key = '${item.orderNumber}_${item.itemName}';
            if (!processedItems.containsKey(key)) {
              processedItems[key] = item;
            }
          }

          final uniqueItems = processedItems.values.toList();

          // Sắp xếp mặc định theo status
          final sortedItems = List<ProcessingItemEntity>.from(uniqueItems);
          _sortItemsByStatus(sortedItems, true);

          emit(
            ProcessingLoaded(
              items: uniqueItems,
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

  // Cập nhật hàm _onRefreshProcessingItems trong ProcessingBloc
  Future<void> _onRefreshProcessingItems(
    RefreshProcessingItemsEvent event,
    Emitter<ProcessingState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      // Lưu lại state hiện tại để đảm bảo không mất dữ liệu
      final existingItems = List<ProcessingItemEntity>.from(currentState.items);

      emit(ProcessingRefreshing(items: existingItems));

      try {
        final result = await refreshProcessingItems(NoParams());

        result.fold(
          (failure) {
            // Nếu API lỗi, vẫn giữ nguyên dữ liệu hiện tại
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

            // Thông báo lỗi
            emit(ProcessingError(message: failure.message));
          },
          (apiItems) {
            // Lấy dữ liệu từ service, BẮT BUỘC dùng forceRefresh: true
            final serviceItems = di.sl<ProcessingDataService>().getAllItems(
              forceRefresh: true,
            );

            // Hợp nhất dữ liệu: API + Service + Existing
            // Chú ý thứ tự ưu tiên: API -> Service -> Existing
            final allItems = [...apiItems, ...serviceItems, ...existingItems];

            // Map để theo dõi các item đã xử lý để loại bỏ trùng lặp
            final processedItems = <String, ProcessingItemEntity>{};

            // Ưu tiên các item mới hơn (đầu mảng) khi loại bỏ trùng lặp
            for (final item in allItems) {
              final key = '${item.orderNumber}_${item.itemName}';
              if (!processedItems.containsKey(key)) {
                processedItems[key] = item;
              }
            }

            // Chuyển đổi từ Map trở lại thành List
            final uniqueItems = processedItems.values.toList();

            // Áp dụng lọc và sắp xếp
            final filteredItems = _filterItems(
              uniqueItems,
              currentState.searchQuery,
            );
            _sortItems(
              filteredItems,
              currentState.sortColumn,
              currentState.ascending,
            );

            emit(
              ProcessingLoaded(
                items: uniqueItems,
                filteredItems: filteredItems,
                sortColumn: currentState.sortColumn,
                ascending: currentState.ascending,
                searchQuery: currentState.searchQuery,
              ),
            );
          },
        );
      } catch (e) {
        // Xử lý bất kỳ lỗi nào và vẫn giữ nguyên dữ liệu hiện tại
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
      // Nếu không phải trạng thái ProcessingLoaded, gọi GetProcessingItemsEvent
      add(GetProcessingItemsEvent());
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

  // Handler mới cho việc cập nhật status
  void _onUpdateItemStatus(
    UpdateItemStatusEvent event,
    Emitter<ProcessingState> emit,
  ) {
    final currentState = state;
    if (currentState is ProcessingLoaded) {
      // Tạo bản sao của danh sách items
      final updatedItems = List<ProcessingItemEntity>.from(currentState.items);

      // Tìm và cập nhật item
      final index = updatedItems.indexWhere(
        (item) =>
            item.orderNumber == event.item.orderNumber &&
            item.itemName == event.item.itemName,
      );

      if (index != -1) {
        // Tạo item mới với status đã cập nhật
        final updatedItem = ProcessingItemModel(
          itemName: event.item.itemName,
          orderNumber: event.item.orderNumber,
          quantity: event.item.quantity,
          exception: event.item.exception,
          timestamp: event.item.timestamp,
          status: event.newStatus,
        );

        // Thay thế item cũ bằng item mới
        updatedItems[index] = updatedItem;

        // Cập nhật service
        di.sl<ProcessingDataService>().updateItemStatus(
          updatedItem.orderNumber,
          updatedItem.itemName,
          event.newStatus,
        );

        // Áp dụng bộ lọc và sắp xếp hiện tại
        final filteredItems = _filterItems(
          updatedItems,
          currentState.searchQuery,
        );
        _sortItems(
          filteredItems,
          currentState.sortColumn,
          currentState.ascending,
        );

        // Emit state mới
        emit(
          currentState.copyWith(
            items: updatedItems,
            filteredItems: filteredItems,
          ),
        );
      }
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
          ? a.timestamp.compareTo(b.timestamp)
          : b.timestamp.compareTo(a.timestamp);
    });
  }

  // Cập nhật phương thức filter để tìm kiếm theo nhiều tiêu chí hơn
  List<ProcessingItemEntity> _filterItems(
    List<ProcessingItemEntity> items,
    String query,
  ) {
    if (query.isEmpty) {
      return List.from(items);
    }

    final lowercaseQuery = query.toLowerCase();

    return items.where((item) {
      // Tìm kiếm theo name và order number
      if (item.itemName.toLowerCase().contains(lowercaseQuery) ||
          item.orderNumber.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Tìm kiếm theo quantity
      if (item.quantity.toString().contains(lowercaseQuery)) {
        return true;
      }

      // Tìm kiếm theo exception
      if (item.exception.toString().contains(lowercaseQuery)) {
        return true;
      }

      // Tìm kiếm theo status
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
}
