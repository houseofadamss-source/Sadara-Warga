import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/surat_entity.dart';
import '../../domain/repositories/surat_repository.dart';
import '../datasources/surat_remote_data_source.dart';
import '../models/surat_model.dart';

class SuratRepositoryImpl implements SuratRepository {
  final SuratRemoteDataSource remoteDataSource;

  SuratRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<SuratEntity>> watchUserSurat(String userId) {
    return remoteDataSource.watchUserSurat(userId);
  }

  @override
  Stream<List<SuratEntity>> watchAllSurat(String status) {
    return remoteDataSource.watchAllSurat(status);
  }

  @override
  Future<Either<Failure, Unit>> submitSurat(SuratEntity entity) async {
    try {
      final model = SuratModel(
        id: entity.id,
        userId: entity.userId,
        nik: entity.nik,
        namaLengkap: entity.namaLengkap,
        ttl: entity.ttl,
        jenisKelamin: entity.jenisKelamin,
        agama: entity.agama,
        statusPerkawinan: entity.statusPerkawinan,
        pekerjaan: entity.pekerjaan,
        tempatTinggal: entity.tempatTinggal,
        keperluan: entity.keperluan,
        status: entity.status,
        nomorSurat: entity.nomorSurat,
        createdAt: entity.createdAt,
      );
      await remoteDataSource.submitSurat(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateSuratStatus(String id, String status, String? nomorSurat) async {
    try {
      await remoteDataSource.updateSuratStatus(id, status, nomorSurat);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
