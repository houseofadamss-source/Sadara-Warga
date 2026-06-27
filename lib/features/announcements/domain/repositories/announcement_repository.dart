import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';

abstract class AnnouncementRepository {
  Stream<List<AnnouncementEntity>> getAnnouncements(String tipe);
  Stream<List<AnnouncementEntity>> getFeaturedAnnouncements();
  Future<Either<Failure, List<AnnouncementEntity>>> getAllAnnouncements();
  Future<Either<Failure, Unit>> addAnnouncement(AnnouncementEntity announcement);
  Future<Either<Failure, Unit>> updateAnnouncement(AnnouncementEntity announcement);
  Future<Either<Failure, Unit>> deleteAnnouncement(String id);
  Future<Either<Failure, Unit>> toggleFeatured(String id, bool currentStatus);
}
