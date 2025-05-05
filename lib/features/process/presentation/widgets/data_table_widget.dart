import 'package:architecture_scan_app/core/constants/app_colors.dart';
import 'package:architecture_scan_app/core/localization/context_extension.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_event.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_state.dart';

class ProcessingDataTable extends StatefulWidget {
  final UserEntity user;

  const ProcessingDataTable({super.key, required this.user});

  @override
  State<ProcessingDataTable> createState() => _ProcessingDataTableState();
}

class _ProcessingDataTableState extends State<ProcessingDataTable> {
  
  final int _pageSize = 15;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
  }

  Future<void> _onSortColumnAsync(BuildContext context, String column) async{
    context.read<ProcessingBloc>().add(
      SortProcessingItemsEvent(column: column, ascending: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessingBloc, ProcessingState>(
      buildWhen: (previous, current) {
        if (previous is ProcessingLoaded && current is ProcessingLoaded) {
          return previous.filteredItems != current.filteredItems ||
                 previous.sortColumn != current.sortColumn ||
                 previous.ascending != current.ascending;
        }
        return true;
      },
      builder: (context, state) {
        if (state is ProcessingInitial || state is ProcessingLoading) {
          return const Center(child: CircularProgressIndicator());

        } else if (state is ProcessingError) {
          return Center(child: Text('${context.multiLanguage.errorTitleUPCASE}: ${state.message}'));

        } else if (state is ProcessingLoaded || state is ProcessingRefreshing) {
          final items = state is ProcessingLoaded
              ? state.filteredItems
              : (state as ProcessingRefreshing).items;
          
          if (items.length <= _currentPage * _pageSize) {
            _currentPage = 0;
          }

          final sortColumn = state is ProcessingLoaded ? state.sortColumn : 'status';
          final ascending = state is ProcessingLoaded ? state.ascending : false;
          final isRefreshing = state is ProcessingRefreshing;

          final int totalItems = items.length;
          final int totalPages = (totalItems / _pageSize).ceil();
          final int startIndex = _currentPage * _pageSize;
          final int endIndex = (startIndex + _pageSize < totalItems)
              ? startIndex + _pageSize
              : totalItems;
              
          final currentPageItems = items.sublist(startIndex, endIndex);

          return Stack(
            children: [
              Column(
                children: [
                  _buildTableHeader(context, sortColumn, ascending),
                  Expanded(
                    child: items.isEmpty
                        ? Center(child: Text(context.multiLanguage.noDataMessageTable))
                        : _buildTableContent(context, currentPageItems),
                  ),
                  if (totalPages > 1)
                    _buildPagination(totalPages),
                ],
              ),
              if (isRefreshing)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }

        return Center(child: Text(context.multiLanguage.noDataMessageTable));
      },
    );
  }

  Widget _buildTableHeader(BuildContext context, String sortColumn, bool ascending) {
    return Container(
      height: 58,
      color: AppColors.headerColor,
      child: Row(
        children: [
          _buildHeaderCell(context.multiLanguage.nameLabel, flex: 2),
          _buildHeaderCell(context.multiLanguage.projectCodeLabel, flex: 2),
          _buildHeaderCell(context.multiLanguage.totalQuantityLabel, flex: 2),
          _buildHeaderCell(context.multiLanguage.deductionLabel, flex: 2),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _onSortColumnAsync(context, "timestamp"),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.multiLanguage.dateLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(
                      width: 25,
                      height: 25,
                      child: Icon(
                        ascending ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTableContent(BuildContext context, List<ProcessingItemEntity> items) {
    return ListView.builder(
      itemCount: items.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) {
        final item = items[index];
        final backgroundColor = index % 2 == 0 ? AppColors.evenRowColor : AppColors.oddRowColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _buildSimpleRow(context, item, backgroundColor),
          );
      },
    );
  }

  Widget _buildSimpleRow(BuildContext context, ProcessingItemEntity item, Color color) {
    return Container(
        height: 50,
        color: color,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  item.mName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  item.mPrjcode ?? '',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  item.mQty?.toString() ?? '0',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  item.qcQtyOut?.toString() ?? '0',
                  style: TextStyle(
                    fontSize: 13,
                    color: item.qcQtyOut! > 0 ? Colors.red : Colors.black,
                    fontWeight: item.qcQtyOut! > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  _formatTimestamp(item.cDate ?? ''),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      height: 40,
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text('${_currentPage + 1} / $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.length < 16) return timestamp;
    return timestamp.substring(0, 16);
  }
}