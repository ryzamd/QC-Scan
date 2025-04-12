import 'package:architecture_scan_app/core/constants/app_routes.dart';
import 'package:architecture_scan_app/core/widgets/confirmation_dialog.dart';
import 'package:architecture_scan_app/core/widgets/error_dialog.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_bloc.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_event.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogoutButton extends StatelessWidget {
  final double width;
  final double height;
  
  const LogoutButton({
    super.key,
    this.width = double.infinity,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutBloc, LogoutState>(
      listener: (context, state) {

        if (state is LogoutSuccess) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );

        } else if (state is LogoutFailure) {
          ErrorDialog.showAsync(
            context,
            title: 'Logout Failed',
            message: state.message,
            onDismiss: () => Navigator.of(context).pop(),
          );
        }
      },
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: () {
            ConfirmationDialog.showAsync(
              context: context,
              title: 'LOGOUT',
              message: 'Are you sure you want to log out?',
              showCancelButton: true,
              onConfirm: () {
                context.read<LogoutBloc>().add(LogoutButtonPressed());
              },
              onCancel: () {},
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFDA7297),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: BlocBuilder<LogoutBloc, LogoutState>(
            builder: (context, state) {
              if (state is LogoutLoading) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              }
              return const Text(
                'LOGOUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}