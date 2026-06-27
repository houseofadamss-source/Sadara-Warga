import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/citizen_entity.dart';
import '../../domain/repositories/citizen_repository.dart';
import '../datasources/citizen_remote_data_source.dart';

class CitizenRepositoryImpl implements CitizenRepository {
  final CitizenRemoteDataSource remoteDataSource;

  CitizenRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<CitizenEntity>> watchCitizens(String status) {
    return remoteDataSource.watchCitizens(status);
  }

  @override
  Future<Either<Failure, Unit>> updateCitizenStatus(String userId, String status) async {
    try {
      await remoteDataSource.updateCitizenStatus(userId, status);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleCitizenRole(String userId, String currentRole) async {
    try {
      final newRole = currentRole == 'super_admin' ? 'warga' : 'super_admin';
      await remoteDataSource.updateCitizenRole(userId, newRole);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetCitizenDevice(String userId) async {
    try {
      await remoteDataSource.resetCitizenDevice(userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
