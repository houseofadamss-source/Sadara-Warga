import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<EventEntity>> watchAllEvents() {
    return remoteDataSource.watchAllEvents();
  }

  @override
  Future<Either<Failure, List<String>>> getUserRsvps(String nik) async {
    try {
      final rsvps = await remoteDataSource.getUserRsvps(nik);
      return Right(rsvps);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleRsvp(String eventId, String nik, bool isCurrentlyRsvped) async {
    try {
      if (isCurrentlyRsvped) {
        await remoteDataSource.removeRsvp(eventId, nik);
      } else {
        await remoteDataSource.addRsvp(eventId, nik);
      }
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addEvent(EventEntity event) async {
    try {
      final model = _toModel(event);
      await remoteDataSource.addEvent(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateEvent(EventEntity event) async {
    try {
      final model = _toModel(event);
      await remoteDataSource.updateEvent(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEvent(String id) async {
    try {
      await remoteDataSource.deleteEvent(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  EventModel _toModel(EventEntity entity) {
    return EventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      location: entity.location,
      latitude: entity.latitude,
      longitude: entity.longitude,
      coordinatorName: entity.coordinatorName,
      coordinatorPhone: entity.coordinatorPhone,
      eventDate: entity.eventDate,
      eventTime: entity.eventTime,
      imageUrl: entity.imageUrl,
      status: entity.status,
    );
  }
}
