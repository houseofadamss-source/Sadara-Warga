import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../entities/event_entity.dart';

abstract class EventRepository {
  Stream<List<EventEntity>> watchAllEvents();
  Future<Either<Failure, List<String>>> getUserRsvps(String nik);
  Future<Either<Failure, Unit>> toggleRsvp(String eventId, String nik, bool isCurrentlyRsvped);
  Future<Either<Failure, Unit>> addEvent(EventEntity event);
  Future<Either<Failure, Unit>> updateEvent(EventEntity event);
  Future<Either<Failure, Unit>> deleteEvent(String id);
}
