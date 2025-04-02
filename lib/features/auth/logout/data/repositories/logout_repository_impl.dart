import 'package:architecture_scan_app/core/network/network_infor.dart';
import 'package:architecture_scan_app/features/auth/logout/data/datasources/logout_datasource.dart';
import 'package:architecture_scan_app/features/auth/logout/domain/repositories/logout_repository.dart';

class LogoutRepositoryImpl implements LogoutRepository {
  final LogoutDataSource dataSource;
  final NetworkInfo networkInfo;

  LogoutRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });

  @override
  Future<bool> logout() async {
    // No need to check for internet connection for logout
    // as we need to clean up local resources regardless
    return await dataSource.logout();
  }
}