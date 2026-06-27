import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_data_source.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementRemoteDataSource remoteDataSource;

  AnnouncementRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<AnnouncementEntity>> getAnnouncements(String tipe) {
    return remoteDataSource.getAnnouncements(tipe);
  }

  @override
  Stream<List<AnnouncementEntity>> getFeaturedAnnouncements() {
    return remoteDataSource.getFeaturedAnnouncements();
  }

  @override
  Future<Either<Failure, List<AnnouncementEntity>>> getAllAnnouncements() async {
    try {
      final models = await remoteDataSource.getAllAnnouncements();
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addAnnouncement(AnnouncementEntity announcement) async {
    try {
      final model = _toModel(announcement);
      await remoteDataSource.addAnnouncement(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAnnouncement(AnnouncementEntity announcement) async {
    try {
      final model = _toModel(announcement);
      await remoteDataSource.updateAnnouncement(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  AnnouncementModel _toModel(AnnouncementEntity announcement) {
    return AnnouncementModel(
      id: announcement.id,
      judul: announcement.judul,
      konten: announcement.konten,
      subJudul: announcement.subJudul,
      fileUrl: announcement.fileUrl,
      tipe: announcement.tipe,
      isFeatured: announcement.isFeatured,
      createdAt: announcement.createdAt,
      authorId: announcement.authorId,
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteAnnouncement(String id) async {
    try {
      await remoteDataSource.deleteAnnouncement(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleFeatured(String id, bool currentStatus) async {
    try {
      await remoteDataSource.toggleFeatured(id, currentStatus);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
