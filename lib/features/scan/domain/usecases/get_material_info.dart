import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/scan_repository.dart';

class GetMaterialInfo {
  final ScanRepository repository;

  GetMaterialInfo(this.repository);

  Future<Either<Failure, Map<String, String>>> call(GetMaterialInfoParams params) async {
    return await repository.getMaterialInfoRepositoryAsync(params.barcode);
  }
}

class GetMaterialInfoParams extends Equatable {
  final String barcode;

  const GetMaterialInfoParams({required this.barcode});

  @override
  List<Object> get props => [barcode];
}