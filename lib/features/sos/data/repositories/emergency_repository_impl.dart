import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/emergency_entity.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_remote_data_source.dart';
import '../models/emergency_model.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final EmergencyRemoteDataSource remoteDataSource;

  EmergencyRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<EmergencyEntity>> watchActiveContacts() {
    return remoteDataSource.watchActiveContacts();
  }

  @override
  Future<Either<Failure, List<EmergencyEntity>>> getAllContacts() async {
    try {
      final models = await remoteDataSource.getAllContacts();
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveContact(EmergencyEntity contact) async {
    try {
      final model = EmergencyModel(
        id: contact.id,
        category: contact.category,
        actionType: contact.actionType,
        phone: contact.phone,
        title: contact.title,
        description: contact.description,
        isActive: contact.isActive,
      );
      await remoteDataSource.saveContact(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteContact(String id) async {
    try {
      await remoteDataSource.deleteContact(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
