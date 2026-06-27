import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/surat_entity.dart';

abstract class SuratRepository {
  Stream<List<SuratEntity>> watchUserSurat(String userId);
  Stream<List<SuratEntity>> watchAllSurat(String status);
  Future<Either<Failure, Unit>> submitSurat(SuratEntity surat);
  Future<Either<Failure, Unit>> updateSuratStatus(String id, String status, String? nomorSurat);
}
