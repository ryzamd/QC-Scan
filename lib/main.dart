import 'package:architecture_scan_app/core/services/exit_confirmation_service.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/pages/profile_page.dart';
import 'package:architecture_scan_app/features/process/presentation/bloc/processing_bloc.dart';
import 'package:architecture_scan_app/features/process/presentation/pages/process_page.dart';
import 'package:architecture_scan_app/features/qc_menu/presentation/pages/qc_menu_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/di/dependencies.dart' as di;
import 'core/localization/language_bloc.dart';
import 'core/services/navigation_service.dart';
import 'features/auth/login/presentation/pages/login_page.dart';
import 'features/scan/presentation/pages/scan_page_provider.dart';
import 'features/auth/login/domain/entities/user_entity.dart';
import 'core/widgets/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    return BlocProvider<LanguageBloc>.value(
      value: di.sl<LanguageBloc>(),
      child: BlocBuilder<LanguageBloc, LanguageState>(
       builder: (context, languageState) {
        return MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Pro Well',
        debugShowCheckedModeBanner: false,
        locale: languageState.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('zh', ''),
              Locale('zh', 'CN'),
              Locale('zh', 'TW'),
              Locale('vi', ''),
            ],
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
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          final args = settings.arguments as UserEntity?;
          
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
              
            case AppRoutes.login:
              return MaterialPageRoute(builder: (_) => const LoginPage());
              
            case AppRoutes.qcMenu:
              return MaterialPageRoute(builder: (_) => QCMenuPage(user: args!),
              );
              
            case AppRoutes.inspection:
              NavigationService().setLastQCRoute(AppRoutes.inspection);
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ScanPageProvider(
                  user: args!,
                  isSpecialFeature: false,
                ),
              );
              
            case AppRoutes.specialFeature:
              NavigationService().setLastQCRoute(AppRoutes.specialFeature);
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ScanPageProvider(
                  user: args!,
                  isSpecialFeature: true,
                ),
              );
              
            case AppRoutes.processingQC1:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => BlocProvider(
                  create: (context) => di.sl<ProcessingBloc>(),
                  child: ProcessingPage(user: args!),
                ),
              );
              
            case AppRoutes.processingQC2:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => BlocProvider(
                  create: (context) => di.sl<ProcessingBloc>(),
                  child: ProcessingPage(user: args!),
                ),
              );
              
            case AppRoutes.profile:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ProfilePage(user: args!),
              );
              
            default:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const LoginPage());
          }
        },
      );
       },
      ),
      

    );
  }
}