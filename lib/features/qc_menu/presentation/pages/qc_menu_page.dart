import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/widgets/scafford_custom.dart';
import '../../../auth/login/domain/entities/user_entity.dart';

class QCMenuPage extends StatelessWidget {
  final UserEntity user;
  
  const QCMenuPage({super.key, required this.user});
  
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService().clearLastQCRoute();
    });
    
    return CustomScaffold(
      title: 'QC Menu',
      user: user,
      showHomeIcon: false,
      currentIndex: 1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF283048),
              Color(0xFF859398),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildFunctionTile(
                context,
                title: 'Inspection',
                icon: Icons.assignment_turned_in,
                route: AppRoutes.inspection,
              ),
              _buildFunctionTile(
                context,
                title: 'Special Feature',
                icon: Icons.star,
                route: AppRoutes.specialFeature,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFunctionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: const Color(0xFFEAEAEA),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pushNamed(
            context,
            route,
            arguments: user,
          );
        },
      ),
    );
  }
}