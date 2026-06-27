import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/version_entity.dart';

abstract class VersionRepository {
  Future<Either<Failure, List<VersionEntity>>> getChangelog();
}
