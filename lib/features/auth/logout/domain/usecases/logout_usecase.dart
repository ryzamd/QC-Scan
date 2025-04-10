import 'package:architecture_scan_app/features/auth/logout/domain/repositories/logout_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:architecture_scan_app/core/errors/failures.dart';

class LogoutUseCase {
  final LogoutRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final result = await repository.logoutRepositoryAsync();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}