import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import 'package:sadarawarga/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
    required String deviceId,
  });

  Future<Either<Failure, Unit>> register({
    required String nik,
    required String nama,
    required String email,
    required String hp,
    required String alamat,
    required String password,
    required String fotoKkUrl,
    required String deviceId,
  });

  Future<Either<Failure, UserEntity>> getCurrentUser();
  
  Future<Either<Failure, Unit>> logout();
}
