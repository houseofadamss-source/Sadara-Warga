import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/citizen_entity.dart';

abstract class CitizenRepository {
  Stream<List<CitizenEntity>> watchCitizens(String status);
  Future<Either<Failure, Unit>> updateCitizenStatus(String userId, String status);
  Future<Either<Failure, Unit>> toggleCitizenRole(String userId, String currentRole);
  Future<Either<Failure, Unit>> resetCitizenDevice(String userId);
}
