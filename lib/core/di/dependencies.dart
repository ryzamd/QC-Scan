// lib/core/di/dependencies.dart
import 'package:architecture_scan_app/core/network/token_interceptor.dart';
import 'package:architecture_scan_app/core/repositories/auth_repository.dart';
import 'package:architecture_scan_app/core/services/secure_storage_service.dart';
import 'package:architecture_scan_app/features/process/domain/usecases/update_qc2_quantity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/language_bloc.dart';
import '../network/dio_client.dart';
import '../network/network_infor.dart';

// Auth feature
import '../../features/auth/login/data/data_sources/login_remote_datasource.dart';
import '../../features/auth/login/data/repositories/user_repository_impl.dart';
import '../../features/auth/login/domain/repositories/user_repository.dart';
import '../../features/auth/login/domain/usecases/user_login.dart';
import '../../features/auth/login/domain/usecases/validate_token.dart';
import '../../features/auth/login/presentation/bloc/login_bloc.dart';
import '../../features/auth/logout/data/datasources/logout_datasource.dart';
import '../../features/auth/logout/data/repositories/logout_repository_impl.dart';
import '../../features/auth/logout/domain/repositories/logout_repository.dart';
import '../../features/auth/logout/domain/usecases/logout_usecase.dart';
import '../../features/auth/logout/presentation/bloc/logout_bloc.dart';

// Scan feature
import '../../features/scan/data/datasources/scan_local_datasource.dart';
import '../../features/scan/data/datasources/scan_remote_datasource.dart';
import '../../features/scan/data/repositories/scan_repository_impl.dart';
import '../../features/scan/domain/repositories/scan_repository.dart';
import '../../features/scan/domain/usecases/get_material_info.dart';
import '../../features/scan/domain/usecases/save_scan_record.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';
import '../../features/auth/login/domain/entities/user_entity.dart';

// Process feature
import '../../features/process/data/datasources/processing_remote_datasource.dart';
import '../../features/process/data/repositories/processing_repository_impl.dart';
import '../../features/process/domain/repositories/processing_repository.dart';
import '../../features/process/domain/usecases/get_processing_items.dart';
import '../../features/process/presentation/bloc/processing_bloc.dart';

final sl = GetIt.instance;

Future<void> initAsync() async {
  await _initSystemCore();
  await _initLoginFeature();
  await _initLogoutFeature();
  await _initScanFeature();
  await _initProcessFeature();
  await _initExternal();
}

Future<void> _initSystemCore() async {
  sl.registerLazySingleton(() => SecureStorageService());

  final dioClient = DioClient();
  sl.registerLazySingleton<DioClient>(() => dioClient);

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl<SecureStorageService>(), sl<DioClient>()),
  );

  final navigatorKey = GlobalKey<NavigatorState>();
  sl.registerLazySingleton<GlobalKey<NavigatorState>>(() => navigatorKey);

  final tokenInterceptor = TokenInterceptor(
    authRepository: sl<AuthRepository>(),
    navigatorKey: sl<GlobalKey<NavigatorState>>(),
  );
  dioClient.dio.interceptors.insert(0, tokenInterceptor);

  sl.registerLazySingleton<Dio>(() => dioClient.dio);

  sl.registerLazySingleton(() => LanguageBloc(sharedPreferences: sl()));

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
}

Future<void> _initLoginFeature() async {
  sl.registerFactory(
    () => LoginBloc(
      userLogin: sl(),
      validateToken: sl(),
    ),
  );

  sl.registerLazySingleton(() => UserLogin(sl()));
  sl.registerLazySingleton(() => ValidateToken(sl()));

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<LoginRemoteDataSource>(
    () => LoginRemoteDataSourceImpl(dio: sl<Dio>()),
  );
}

Future<void> _initLogoutFeature() async {
  sl.registerLazySingleton<LogoutDataSource>(
    () => LogoutDataSourceImpl(
      sharedPreferences: sl(),
      dioClient: sl(),
    ),
  );

  sl.registerLazySingleton<LogoutRepository>(
    () => LogoutRepositoryImpl(
      dataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  sl.registerFactory(
    () => LogoutBloc(
      logoutUseCase: sl(),
    ),
  );
}

Future<void> _initScanFeature() async {
  sl.registerFactoryParam<ScanBloc, UserEntity, void>(
    (user, _) => ScanBloc(
      getMaterialInfo: sl(),
      saveScanRecord: sl(),
      remoteDataSource: sl<ScanRemoteDataSource>(),
      currentUser: user,
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerLazySingleton(() => GetMaterialInfo(sl()));
  sl.registerLazySingleton(() => SaveScanRecord(sl()));

  sl.registerLazySingleton<ScanRepository>(
    () => ScanRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<ScanLocalDataSource>(
    () => ScanLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<ScanRemoteDataSource>(
    () => ScanRemoteDataSourceImpl(dio: sl()),
  );
}

Future<void> _initProcessFeature() async {
  sl.registerFactory(
    () => ProcessingBloc(
      getProcessingItems: sl(),
      updateQC2Quantity: sl(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerLazySingleton(() => GetProcessingItems(sl()));
  sl.registerLazySingleton(() => UpdateQC2Quantity(sl()));

  sl.registerLazySingleton<ProcessingRepository>(
    () => ProcessingRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<ProcessingRemoteDataSource>(
    () => ProcessingRemoteDataSourceImpl(dio: sl(), useMockData: false),
  );
}

Future<void> _initExternal() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
