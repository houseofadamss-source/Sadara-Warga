import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_data_source.dart';
import '../models/report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ReportEntity>> watchUserReports(String userId) {
    return remoteDataSource.watchUserReports(userId);
  }

  @override
  Stream<List<ReportEntity>> watchAllReports() {
    return remoteDataSource.watchAllReports();
  }

  @override
  Future<Either<Failure, Unit>> submitReport({
    required ReportEntity report,
    required String? localImagePath,
  }) async {
    try {
      final model = ReportModel(
        id: report.id,
        userId: report.userId,
        namaWarga: report.namaWarga,
        judulLaporan: report.judulLaporan,
        deskripsi: report.deskripsi,
        kategori: report.kategori,
        fotoUrl: report.fotoUrl,
        status: report.status,
        latitude: report.latitude,
        longitude: report.longitude,
        createdAt: report.createdAt,
      );
      await remoteDataSource.submitReport(model, localImagePath);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateReportStatus(String id, String newStatus) async {
    try {
      await remoteDataSource.updateReportStatus(id, newStatus);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
