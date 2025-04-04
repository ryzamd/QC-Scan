import 'package:architecture_scan_app/core/di/dependencies.dart' as di;
import 'package:architecture_scan_app/core/repositories/auth_repository.dart';
import 'package:architecture_scan_app/core/widgets/scafford_custom.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_event.dart';
import '../widgets/data_table_widget.dart';

class ProcessingPage extends StatefulWidget {
  final UserEntity user;
  const ProcessingPage({super.key, required this.user});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      di.sl<AuthRepository>().debugTokenState().then((_) {
        if (mounted) {
          context.read<ProcessingBloc>().add(
            GetProcessingItemsEvent(userName: widget.user.name),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProcessingBloc, ProcessingState>(
      listener: (context, state) {
        if (state is ProcessingUpdatedState || state is ProcessingError) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        if (state is ProcessingUpdatedState) {
          
          context.read<ProcessingBloc>().add(GetProcessingItemsEvent(userName: widget.user.name));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProcessingError) {

          context.read<ProcessingBloc>().add(GetProcessingItemsEvent(userName: widget.user.name));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      child: CustomScaffold(
        title: 'PROCESSING',
        user: widget.user,
        currentIndex: 0,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProcessingDataTable(user: widget.user),
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
              context.read<ProcessingBloc>().add(
                RefreshProcessingItemsEvent(userName: widget.user.name),
              );
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
      ),
    );
  }

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        ),
        onChanged: (value) {
          context.read<ProcessingBloc>().add(
            SearchProcessingItemsEvent(query: value),
          );
        },
      ),
    );
  }
}