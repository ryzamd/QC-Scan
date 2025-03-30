// lib/features/auth/login/presentation/pages/login_page.dart
import 'package:architecture_scan_app/core/widgets/logo_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/widgets/dialog_custom.dart';
import '../../../../../core/di/dependencies.dart' as di;
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/login_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for the text fields
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Selected department state
  String _selectedDepartment = 'QC 1';
  final List<String> _departments = ['QC 1', 'QC 2', 'QC 3'];
  
  // Focus nodes to control keyboard focus
  final FocusNode _userIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    // Clean up controllers and focus nodes when the widget is disposed
    _userIdController.dispose();
    _passwordController.dispose();
    _userIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Function to dismiss keyboard
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // Function to handle department selection
  void _handleDepartmentChange(String? department) {
    if (department != null && department != _selectedDepartment) {
      setState(() {
        _selectedDepartment = department;
      });
      
      // Small delay to allow UI to update before attempting to focus
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // This ensures we can focus on fields after department selection
          FocusScope.of(context).canRequestFocus = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return BlocProvider(
      create: (context) => di.sl<LoginBloc>(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // If login is successful, navigate to the scan page (processing route)
            // Pass the user entity to the processing page
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.processing,
              arguments: state.user,
            );
          } else if (state is LoginFailure) {
            // If login fails, show an error dialog
            showDialog(
              context: context,
              builder: (context) => CustomAlertDialog(
                title: 'Login Failed',
                message: state.message,
                onConfirm: () => Navigator.pop(context),
              ),
            );
          }
        },
        child: Scaffold(
          // Prevent resizing when keyboard appears
          resizeToAvoidBottomInset: false,
          body: Container(
            // Gradient background as per original design
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF3a7bd5), // Matching the blue in screenshots
                  Color(0xFF3a6073),
                ],
              ),
            ),
            height: screenHeight,
            child: SafeArea(
              bottom: false, // Don't respect bottom safe area to avoid extra padding
              child: Stack(
                children: [
                  // Main content with limited scroll
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Non-scrollable top part with logo
                          const SizedBox(height: 30),
                          buildLogoWidget(),
                          const SizedBox(height: 24),
                          
                          // Scrollable form part (limited height)
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                // Disable scroll bounce/glow
                                physics: const ClampingScrollPhysics(),
                                // Prevent scrolling beyond content
                                shrinkWrap: true,
                                children: [
                                  // Card for input fields
                                  Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    color: const Color(0xFF1d3557).withValues(alpha: 0.9),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Username field
                                          LoginTextField(
                                            controller: _userIdController,
                                            hintText: '请选择用户名', // Please select username
                                            focusNode: _userIdFocusNode,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your username';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) {
                                              FocusScope.of(context).requestFocus(_passwordFocusNode);
                                            },
                                            onTap: () {
                                              // Ensure focus can be requested
                                              FocusScope.of(context).canRequestFocus = true;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          // Password field
                                          LoginTextField(
                                            controller: _passwordController,
                                            hintText: '输入密码', // Enter password
                                            obscureText: true,
                                            focusNode: _passwordFocusNode,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) {
                                              _dismissKeyboard();
                                            },
                                            onTap: () {
                                              // Ensure focus can be requested
                                              FocusScope.of(context).canRequestFocus = true;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          // Department dropdown
                                          DepartmentDropdown(
                                            selectedDepartment: _selectedDepartment,
                                            departments: _departments,
                                            onChanged: _handleDepartmentChange,
                                          ),
                                          const SizedBox(height: 24),
                                          // Login button with loading state
                                          BlocBuilder<LoginBloc, LoginState>(
                                            builder: (context, state) {
                                              return LoginButton(
                                                isLoading: state is LoginLoading,
                                                onPressed: () {
                                                  // Dismiss keyboard
                                                  _dismissKeyboard();
                                                  
                                                  // Validate the form before submitting
                                                  if (_formKey.currentState!.validate()) {
                                                    // Dispatch login event to the bloc
                                                    context.read<LoginBloc>().add(
                                                          LoginButtonPressed(
                                                            userId: _userIdController.text,
                                                            password: _passwordController.text,
                                                            department: _selectedDepartment,
                                                          ),
                                                        );
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Additional padding at the bottom to ensure all elements are visible
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Conditionally show a bottom padding shadow when keyboard is visible
                  if (isKeyboardVisible)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}