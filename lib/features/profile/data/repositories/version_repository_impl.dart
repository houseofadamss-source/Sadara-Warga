import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/version_entity.dart';
import '../../domain/repositories/version_repository.dart';
import '../datasources/version_remote_data_source.dart';

class VersionRepositoryImpl implements VersionRepository {
  final VersionRemoteDataSource remoteDataSource;

  VersionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VersionEntity>>> getChangelog() async {
    try {
      final results = await remoteDataSource.getVersionsFromGithub();
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
