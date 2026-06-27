import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/report_entity.dart';

abstract class ReportRepository {
  Stream<List<ReportEntity>> watchUserReports(String userId);
  Stream<List<ReportEntity>> watchAllReports();
  Future<Either<Failure, Unit>> submitReport({
    required ReportEntity report,
    required String? localImagePath,
  });
  Future<Either<Failure, Unit>> updateReportStatus(String id, String newStatus);
}
