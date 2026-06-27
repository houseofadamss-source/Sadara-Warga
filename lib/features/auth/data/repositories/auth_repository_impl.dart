import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import 'package:sadarawarga/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sadarawarga/features/auth/domain/entities/user_entity.dart';
import 'package:sadarawarga/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      final userModel = await remoteDataSource.login(email, password, deviceId);
      return Right(userModel);
    } catch (e) {
      if (e.toString().contains('DEVICE_LOCKED')) {
        return const Left(AuthFailure('Akun Anda terikat pada perangkat lain.'));
      }
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> register({
    required String nik,
    required String nama,
    required String email,
    required String hp,
    required String alamat,
    required String password,
    required String fotoKkUrl,
    required String deviceId,
  }) async {
    try {
      await remoteDataSource.register(
        nik: nik,
        nama: nama,
        email: email,
        hp: hp,
        alamat: alamat,
        password: password,
        fotoKkUrl: fotoKkUrl,
        deviceId: deviceId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
