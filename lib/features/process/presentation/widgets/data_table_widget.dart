// lib/features/process/presentation/widgets/data_table_widget.dart
import 'package:architecture_scan_app/core/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/domain/entities/processing_item_entity.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_event.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_state.dart';

class ProcessingDataTable extends StatefulWidget {
  const ProcessingDataTable({super.key});

  @override
  State<ProcessingDataTable> createState() => _ProcessingDataTableState();
}

class _ProcessingDataTableState extends State<ProcessingDataTable> {
  @override
  void initState() {
    super.initState();
    context.read<ProcessingBloc>().add(GetProcessingItemsEvent());
  }

  void _onSortColumn(String column) {
    context.read<ProcessingBloc>().add(
      SortProcessingItemsEvent(
        column: column,
        ascending: true, // Initial value, bloc will toggle if same column
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
                  _buildTableHeader(sortColumn, ascending),
                  Expanded(
                    child:
                        items.isEmpty
                            ? const Center(child: Text('No data available'))
                            : _buildTableBody(context, items),
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

  Widget _buildTableHeader(String sortColumn, bool ascending) {
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
          _buildSignalHeader(sortColumn, ascending),
          _buildHeaderCell('Name', flex: 2),
          _buildHeaderCell('Order\nNumber', flex: 2),
          _buildHeaderCell('Quantity', flex: 2),
          _buildHeaderCell('Minus', flex: 2),
          _buildTimestampHeader(sortColumn, ascending),
        ],
      ),
    );
  }

  Widget _buildSignalHeader(String sortColumn, bool ascending) {
    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: () => _onSortColumn("status"),
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

  Widget _buildTimestampHeader(String sortColumn, bool ascending) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () => _onSortColumn("timestamp"),
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

  Widget _buildTableBody(
    BuildContext context,
    List<ProcessingItemEntity> items,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => _showStatusUpdateDialog(context, items[index]),
          child: Container(
            height: 50,
            color:
                index % 2 == 0
                    ? const Color(0xFFFAF1E6)
                    : const Color(0xFFF5E6CC),
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: _buildDataRow(items[index]),
            ),
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
              item.itemName,
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
              item.orderNumber,
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
              item.quantity.toString(),
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
              item.exception.toString(),
              style: TextStyle(
                fontSize: 13,
                color: item.exception > 0 ? Colors.red : Colors.black,
                fontWeight:
                    item.exception > 0 ? FontWeight.bold : FontWeight.normal,
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
              _formatTimestamp(item.timestamp),
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
    // Format timestamp for display if needed
    return timestamp.substring(
      0,
      16,
    ); // Just show date and time without milliseconds
  }

  void _showStatusUpdateDialog(BuildContext context, ProcessingItemEntity item) {
  // Lưu tham chiếu đến bloc trước khi mở dialog
  final bloc = context.read<ProcessingBloc>();
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: const Text('UPDATE RECORD STATUS',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      actions: [],
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item.itemName}'),
            const SizedBox(height: 12),
            Text('Order: ${item.orderNumber}'),
            const SizedBox(height: 8),
            Text('Quantity: ${item.quantity}'),
            
            if (item.exception > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Exception: ${item.exception}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Current status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildStatusBadge(item.status),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text('Select new status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            // Status options in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    bloc.add(UpdateItemStatusEvent(
                      item: item,
                      newStatus: SignalStatus.failed,
                    ));
                    Navigator.pop(dialogContext);
                  },
                  child: _buildStatusBadge(SignalStatus.failed),
                ),
                GestureDetector(
                  onTap: () {
                    bloc.add(UpdateItemStatusEvent(
                      item: item,
                      newStatus: SignalStatus.success,
                    ));
                    Navigator.pop(dialogContext);
                  },
                  child: _buildStatusBadge(SignalStatus.success),
                ),
              ],
            ),
          ],
        ),
      ),
  );
}

  // Hiển thị badge cho status
  Widget _buildStatusBadge(SignalStatus status) {
    Color color;
    String text;

    switch (status) {
      case SignalStatus.success:
        color = Colors.green;
        text = 'Success';
        break;
      case SignalStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case SignalStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      width: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
