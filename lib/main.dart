// lib/main.dart
import 'package:architecture_scan_app/core/services/exit_confirmation_service.dart';
import 'package:architecture_scan_app/features/auth/login/data/models/user_model.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/pages/process_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/di/dependencies.dart' as di;
import 'features/auth/login/presentation/pages/login_page.dart';
import 'features/scan/presentation/pages/scan_page_provider.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final BackButtonService _backButtonService = BackButtonService();

  @override
  void initState() {
    super.initState();
    // Khởi tạo service sau khi build hoàn tất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backButtonService.initialize(_navigatorKey.currentContext!);
    });
  }

  @override
  void dispose() {
    _backButtonService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: _navigatorKey,
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
              builder:
                  (context) => BlocProvider(
                    create: (context) => di.sl<ProcessingBloc>(),
                    child: const ProcessingPage(),
                  ),
            );
          } else if (settings.name == AppRoutes.scan) {
            // Nếu arguments là null, lấy từ mockdata
            if (settings.arguments == null) {
              // Sử dụng user mặc định từ mockdata
              final defaultUser =
                  UserModel.dummyUsers[0]; // Lấy admin hoặc user tùy nhu cầu
              return MaterialPageRoute(
                builder: (context) => ScanPageProvider(user: defaultUser),
              );
            } else {
              // Nếu có arguments hợp lệ
              final args = settings.arguments as UserEntity;
              return MaterialPageRoute(
                builder: (context) => ScanPageProvider(user: args),
              );
            }
          } else if (settings.name == AppRoutes.processRecords) {
            // Extract user from arguments
            final args = settings.arguments as UserEntity;
            return MaterialPageRoute(builder: (context) => ProcessingPage());
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
