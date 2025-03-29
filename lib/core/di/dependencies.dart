// lib/core/di/dependencies.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../network/dio_client.dart';
import '../network/network_infor.dart';
import '../../features/auth/login/data/data_sources/login_remote_datasource.dart';
import '../../features/auth/login/data/repositories/user_repository_impl.dart';
import '../../features/auth/login/domain/repositories/user_repository.dart';
import '../../features/auth/login/domain/usecases/user_login.dart';
import '../../features/auth/login/domain/usecases/validate_token.dart';
import '../../features/auth/login/presentation/bloc/login_bloc.dart';

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

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  //! External
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton(() => DioClient().dio);
}