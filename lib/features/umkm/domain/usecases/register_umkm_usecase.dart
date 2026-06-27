import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import 'package:sadarawarga/core/usecases/usecase.dart';
import '../entities/umkm_entity.dart';
import '../repositories/umkm_repository.dart';

class RegisterUmkmUseCase implements UseCase<Unit, UmkmEntity> {
  final UmkmRepository repository;

  RegisterUmkmUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UmkmEntity umkm) async {
    return await repository.registerUmkm(umkm);
  }
}
