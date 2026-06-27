import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../entities/emergency_entity.dart';

abstract class EmergencyRepository {
  Stream<List<EmergencyEntity>> watchActiveContacts();
  Future<Either<Failure, List<EmergencyEntity>>> getAllContacts();
  Future<Either<Failure, Unit>> saveContact(EmergencyEntity contact);
  Future<Either<Failure, Unit>> deleteContact(String id);
}
