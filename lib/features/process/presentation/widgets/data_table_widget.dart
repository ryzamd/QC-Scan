import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_event.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_state.dart';

class ProcessingDataTable extends StatelessWidget {
  const ProcessingDataTable({super.key});

  void _onSortColumn(BuildContext context, String column) {
    context.read<ProcessingBloc>().add(
      SortProcessingItemsEvent(
        column: column,
        ascending: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessingBloc, ProcessingState>(
      builder: (context, state) {
        if (state is ProcessingInitial || state is ProcessingLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProcessingError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is ProcessingLoaded || state is ProcessingRefreshing) {
          final items =
              state is ProcessingLoaded
                  ? state.filteredItems
                  : (state as ProcessingRefreshing).items;

          final sortColumn =
              state is ProcessingLoaded ? state.sortColumn : 'status';
          final ascending = state is ProcessingLoaded ? state.ascending : true;
          final isRefreshing = state is ProcessingRefreshing;

          return Stack(
            children: [
              Column(
                children: [
                  _buildTableHeader(context, sortColumn, ascending),
                  Expanded(
                    child:
                        items.isEmpty
                            ? const Center(child: Text('No data available'))
                            : _buildTableBody(items),
                  ),
                ],
              ),
              if (isRefreshing)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }

        return const Center(child: Text('No data'));
      },
    );
  }

  Widget _buildTableHeader(BuildContext context, String sortColumn, bool ascending) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1d3557),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSignalHeader(context, sortColumn, ascending),
          _buildHeaderCell('Name', flex: 2),
          _buildHeaderCell('Order\nNumber', flex: 2),
          _buildHeaderCell('Quantity', flex: 2),
          _buildHeaderCell('Minus', flex: 2),
          _buildTimestampHeader(context, sortColumn, ascending),
        ],
      ),
    );
  }

  Widget _buildSignalHeader(BuildContext context, String sortColumn, bool ascending) {
    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: () => _onSortColumn(context, "status"),
        child: Container(
          alignment: Alignment.center,
          child: Icon(
            sortColumn == "status"
                ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTimestampHeader(BuildContext context, String sortColumn, bool ascending) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () => _onSortColumn(context, "timestamp"),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                child: Text(
                  'Times',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                sortColumn == "timestamp"
                    ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                    : Icons.unfold_more,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTableBody(List<ProcessingItemEntity> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          height: 50,
          color:
              index % 2 == 0
                  ? const Color(0xFFFAF1E6)
                  : const Color(0xFFF5E6CC),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: _buildDataRow(items[index]),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(ProcessingItemEntity item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: _buildSignalIndicator(item.status),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Text(
              item.mName!,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.left,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Text(
              item.mPrjcode!,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.left,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              item.mQty.toString(),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              item.qcQtyOut.toString(),
              style: TextStyle(
                fontSize: 13,
                color: item.qcQtyOut! > 0 ? Colors.red : Colors.black,
                fontWeight:
                    item.qcQtyOut! > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Text(
              _formatTimestamp(item.cDate!),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalIndicator(SignalStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case SignalStatus.success:
        color = Colors.green;
        icon = Icons.circle_rounded;
        break;
      case SignalStatus.pending:
        color = Colors.orange;
        icon = Icons.circle_rounded;
        break;
      case SignalStatus.failed:
        color = Colors.red;
        icon = Icons.circle_rounded;
        break;
    }

    return Container(
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 10),
    );
  }

  String _formatTimestamp(String timestamp) {
    // Format timestamp for display
    return timestamp.substring(
      0,
      16,
    ); // Just show date and time without milliseconds
  }
}