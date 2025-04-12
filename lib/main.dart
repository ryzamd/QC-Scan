import 'package:architecture_scan_app/core/services/exit_confirmation_service.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/pages/profile_page.dart';
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await di.initAsync();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backButtonService.initializeAsync(_navigatorKey.currentContext!);
    });
  }

  @override
  void dispose() {
    _backButtonService.disposeAsync();
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
        if (settings.name == AppRoutes.processing) {
          final args = settings.arguments as UserEntity;

          return MaterialPageRoute(
            builder:
                (context) => BlocProvider(
                  create: (context) => di.sl<ProcessingBloc>(),
                  child: ProcessingPage(user: args),
                ),
          );

        } else if (settings.name == AppRoutes.scan) {
          if (settings.arguments != null) {

            final args = settings.arguments as UserEntity;

            return MaterialPageRoute(
              builder: (context) => ScanPageProvider(user: args),
            );

          } else {
            return MaterialPageRoute(builder: (_) => const LoginPage());

          }
        } else if (settings.name == AppRoutes.processRecords) {
          final args = settings.arguments as UserEntity;

          return MaterialPageRoute(
            builder: (context) => ProcessingPage(user: args),
          );

        } else if (settings.name == AppRoutes.profile) {
          final args = settings.arguments as UserEntity;

          return MaterialPageRoute(
            builder: (context) => ProfilePage(user: args),
          );
        }

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
