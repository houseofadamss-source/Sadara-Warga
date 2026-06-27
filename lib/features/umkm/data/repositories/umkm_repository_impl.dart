import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/umkm_entity.dart';
import '../../domain/repositories/umkm_repository.dart';
import '../datasources/umkm_remote_data_source.dart';
import '../models/umkm_model.dart';

class UmkmRepositoryImpl implements UmkmRepository {
  final UmkmRemoteDataSource remoteDataSource;

  UmkmRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<UmkmEntity>> getFeaturedUmkm() {
    return remoteDataSource.getFeaturedUmkm();
  }

  @override
  Future<Either<Failure, List<UmkmEntity>>> getAllApprovedUmkm() async {
    try {
      final models = await remoteDataSource.getAllApprovedUmkm();
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<UmkmEntity>> getUmkmByStatus(String status) {
    return remoteDataSource.getUmkmByStatus(status);
  }

  @override
  Future<Either<Failure, Unit>> registerUmkm(UmkmEntity umkm) async {
    try {
      final model = UmkmModel(
        id: umkm.id,
        userId: umkm.userId,
        namaBisnis: umkm.namaBisnis,
        jenisDagangan: umkm.jenisDagangan,
        produkUtama: umkm.produkUtama,
        nomorWa: umkm.nomorWa,
        deskripsi: umkm.deskripsi,
        jamBuka: umkm.jamBuka,
        jamTutup: umkm.jamTutup,
        hariLibur: umkm.hariLibur,
        fotoUrl: umkm.fotoUrl,
        latitude: umkm.latitude,
        longitude: umkm.longitude,
        status: umkm.status,
        isWeeklyFeatured: umkm.isWeeklyFeatured,
        isPushedToOsm: umkm.isPushedToOsm,
      );
      await remoteDataSource.registerUmkm(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUmkmStatus(String id, String status) async {
    try {
      await remoteDataSource.updateUmkmStatus(id, status);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleFeatured(String id, bool currentVal) async {
    try {
      await remoteDataSource.toggleFeatured(id, currentVal);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> pushToOsm(UmkmEntity umkm) async {
    try {
      final model = UmkmModel(
        id: umkm.id,
        userId: umkm.userId,
        namaBisnis: umkm.namaBisnis,
        jenisDagangan: umkm.jenisDagangan,
        produkUtama: umkm.produkUtama,
        nomorWa: umkm.nomorWa,
        deskripsi: umkm.deskripsi,
        jamBuka: umkm.jamBuka,
        jamTutup: umkm.jamTutup,
        hariLibur: umkm.hariLibur,
        fotoUrl: umkm.fotoUrl,
        latitude: umkm.latitude,
        longitude: umkm.longitude,
        status: umkm.status,
        isWeeklyFeatured: umkm.isWeeklyFeatured,
        isPushedToOsm: umkm.isPushedToOsm,
      );
      final ok = await remoteDataSource.pushToOsm(model);
      return ok ? const Right(unit) : const Left(ServerFailure('Gagal push ke OSM'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
