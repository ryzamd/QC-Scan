// lib/core/di/dependencies.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
import '../network/network_infor.dart';

// Auth feature
import '../../features/auth/login/data/data_sources/login_remote_datasource.dart';
import '../../features/auth/login/data/repositories/user_repository_impl.dart';
import '../../features/auth/login/domain/repositories/user_repository.dart';
import '../../features/auth/login/domain/usecases/user_login.dart';
import '../../features/auth/login/domain/usecases/validate_token.dart';
import '../../features/auth/login/presentation/bloc/login_bloc.dart';

// Scan feature
import '../../features/scan/data/datasources/scan_local_datasource.dart';
import '../../features/scan/data/datasources/scan_remote_datasource.dart';
import '../../features/scan/data/repositories/scan_repository_impl.dart';
import '../../features/scan/domain/repositories/scan_repository.dart';
import '../../features/scan/domain/usecases/get_material_info.dart';
import '../../features/scan/domain/usecases/save_scan_record.dart';
import '../../features/scan/domain/usecases/send_to_processing.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';
import '../../features/auth/login/domain/entities/user_entity.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Login
  // BLoC
  sl.registerFactory(
    () => LoginBloc(
      userLogin: sl(),
      validateToken: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => UserLogin(sl()));
  sl.registerLazySingleton(() => ValidateToken(sl()));

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<LoginRemoteDataSource>(
    () => LoginRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  //! Features - Scan
  // BLoC - Factory for each instance (created when needed)
  sl.registerFactoryParam<ScanBloc, UserEntity, void>(
    (user, _) => ScanBloc(
      getMaterialInfo: sl(),
      saveScanRecord: sl(),
      sendToProcessing: sl(),
      currentUser: user,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMaterialInfo(sl()));
  sl.registerLazySingleton(() => SaveScanRecord(sl()));
  sl.registerLazySingleton(() => SendToProcessing(sl()));

  // Repository
  sl.registerLazySingleton<ScanRepository>(
    () => ScanRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ScanLocalDataSource>(
    () => ScanLocalDataSourceImpl(sharedPreferences: sl()),
  );
  
  sl.registerLazySingleton<ScanRemoteDataSource>(
    () => ScanRemoteDataSourceImpl(dio: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton(() => DioClient().dio);
}