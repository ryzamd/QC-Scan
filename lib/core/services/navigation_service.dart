import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();
  
  String? lastQCRoute;
  String? previousMainRoute;
  bool isInSpecialFeature = false;
  
  void setLastQCRoute(String? route) {
    if (route != null && (route.contains('/qc_menu/'))) {
      lastQCRoute = route;
      isInSpecialFeature = route.contains('/special_feature');
    }
  }
  
  void clearLastQCRoute() {
    lastQCRoute = null;
  }
  
  void enterProcessingPage() {
    previousMainRoute = AppRoutes.processingQC1;
  }
  
  void enterProfilePage() {
    previousMainRoute = AppRoutes.qcMenu;
    clearLastQCRoute();
  }
  
  String getWorkDestination(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    if (currentRoute == AppRoutes.processingQC1 || currentRoute == AppRoutes.processingQC2) {
      return lastQCRoute ?? AppRoutes.qcMenu;
    }
    
    if (currentRoute == AppRoutes.profile) {
      return AppRoutes.qcMenu;
    }
    
    return lastQCRoute ?? AppRoutes.qcMenu;
  }
  
  bool shouldShowBackButton(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    
    if (currentRoute != null && currentRoute.startsWith('/qc_menu/')) {
      return true;
    }
    
    if (currentRoute == AppRoutes.qcMenu ||
        currentRoute == AppRoutes.profile) {
      return false;
    }
    
    return true;
  }
  
  void handleBackButton(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    
    if (currentRoute == AppRoutes.inspection || currentRoute == AppRoutes.specialFeature
          || currentRoute == AppRoutes.processingQC1 || currentRoute == AppRoutes.processingQC2) {
      Navigator.pop(context);
    }
    else if (currentRoute != null && currentRoute.startsWith('/qc_menu/')) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.qcMenu,
        arguments: ModalRoute.of(context)?.settings.arguments
      );
    }
  }
}