import 'package:architecture_scan_app/core/widgets/scafford_custom.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_event.dart';
import '../widgets/data_table_widget.dart';

class ProcessingPage extends StatelessWidget {
  final UserEntity user;
  const ProcessingPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Fetch data when page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcessingBloc>().add(GetProcessingItemsEvent(userName: user.name));
    });

    return CustomScaffold(
      title: 'PROCESSING',
      user: user,
      currentIndex: 0,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(context),
            const SizedBox(height: 8),
            // Data table
            Expanded(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProcessingDataTable(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            // Refresh data with user's name
            context.read<ProcessingBloc>().add(RefreshProcessingItemsEvent(userName: user.name));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing data...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Refresh data',
        ),
      ],
    );
  }
  
  // Search bar widget
  Widget _buildSearchBar(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              // Clear search and reset data
              context.read<ProcessingBloc>().add(
                const SearchProcessingItemsEvent(query: ''),
              );
              controller.clear();
              FocusScope.of(context).unfocus();
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          // Send search event when text changes
          context.read<ProcessingBloc>().add(
            SearchProcessingItemsEvent(query: value),
          );
        },
      ),
    );
  }
}