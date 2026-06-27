import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadarawarga/core/error/failures.dart';
import 'package:sadarawarga/core/usecases/usecase.dart';
import 'package:sadarawarga/features/auth/domain/entities/user_entity.dart';
import 'package:sadarawarga/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.login(
      email: params.email,
      password: params.password,
      deviceId: params.deviceId,
    );
  }
}

class LoginParams extends Equatable {
  final String email;
  final String password;
  final String deviceId;

  const LoginParams({required this.email, required this.password, required this.deviceId});

  @override
  List<Object> get props => [email, password, deviceId];
}
