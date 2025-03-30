// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/di/dependencies.dart' as di;
import 'features/auth/login/presentation/pages/login_page.dart';
import 'features/scan/presentation/pages/scan_page_provider.dart';
import 'features/process/presentation/pages/process_page.dart';
import 'features/auth/login/domain/entities/user_entity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize dependencies
  await di.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Well',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        // For routes that need to pass parameters
        if (settings.name == AppRoutes.processing) {
          // Extract user from arguments
          final args = settings.arguments as UserEntity;
          return MaterialPageRoute(
            builder: (context) => ScanPageProvider(user: args),
          );
        } else if (settings.name == AppRoutes.processRecords) {
          // Extract user from arguments
          final args = settings.arguments as UserEntity;
          return MaterialPageRoute(
            builder: (context) => ProcessPage(user: args),
          );
        }
        
        // Standard routes
        switch (settings.name) {
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}