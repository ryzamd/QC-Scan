import 'dart:async';
import 'package:architecture_scan_app/core/di/dependencies.dart' as di;
import 'package:architecture_scan_app/core/repositories/auth_repository.dart';
import 'package:architecture_scan_app/core/widgets/notification_dialog.dart';
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

class _ProcessingPageState extends State<ProcessingPage> with WidgetsBindingObserver {

  static const Duration _debounceTime = Duration(milliseconds: 300);
  
  Timer? _debounce;
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await di.sl<AuthRepository>().debugTokenStateAsync();
      if (mounted) {

        final now = DateTime.now();
        final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 00:00:00';
        context.read<ProcessingBloc>().add(GetProcessingItemsEvent(date: formattedDate));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    if(!context.mounted) return;
    context.read<ProcessingBloc>().loadData();
  }

  void _refreshData() {
    if(!context.mounted) return;
    context.read<ProcessingBloc>().refreshData();
  }

  

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProcessingBloc, ProcessingState>(
      listenWhen: (previous, current) =>
          current is ProcessingUpdatedState || current is ProcessingError,
      listener: (context, state) {

        if ((state is ProcessingUpdatedState || state is ProcessingError) && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (state is ProcessingUpdatedState) {
          _loadData();
         
        } else if (state is ProcessingError) {
          _loadData();
          NotificationDialog.showAsync(
            context: context,
            title: 'Error',
            message: state.message,
            titleColor: Colors.red,
            buttonColor: Colors.red,
          );
        }
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return CustomScaffold(
      title: 'PROCESSING',
      showBackButton: false,
      user: widget.user,
      currentIndex: 0,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [

            _buildSearchBar(),

            const SizedBox(height: 8),
            Expanded(
              child: Card(
                elevation: 4, // Reduced from 8
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
          icon: const Icon(Icons.calendar_month, color: Colors.white),
          onPressed: () => _selectDateAsync(context),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        // Simplified shadow
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<ProcessingBloc>().add(
                    const SearchProcessingItemsEvent(query: ''),
                  );
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        ),
        onChanged: _handleSearchWithDebounce,
      ),
    );
  }
  
  void _handleSearchWithDebounce(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(_debounceTime, () {
      if (mounted) {
        context.read<ProcessingBloc>().add(
          SearchProcessingItemsEvent(query: value),
        );
      }
    });
  }

  Future<void> _selectDateAsync(BuildContext context) async {

    final currentState = context.read<ProcessingBloc>().state;
    final DateTime initialDate = currentState is ProcessingLoaded ? currentState.selectedDate : DateTime.now();
        
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if(!context.mounted) return;

    if (picked != null && picked != initialDate) {
      context.read<ProcessingBloc>().add(SelectDateEvent(selectedDate: picked));
    }
  }
}