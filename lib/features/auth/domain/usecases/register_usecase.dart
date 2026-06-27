import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadarawarga/core/error/failures.dart';
import 'package:sadarawarga/core/usecases/usecase.dart';
import 'package:sadarawarga/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<Unit, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RegisterParams params) async {
    return await repository.register(
      nik: params.nik,
      nama: params.nama,
      email: params.email,
      hp: params.hp,
      alamat: params.alamat,
      password: params.password,
      fotoKkUrl: params.fotoKkUrl,
      deviceId: params.deviceId,
    );
  }
}

class RegisterParams extends Equatable {
  final String nik;
  final String nama;
  final String email;
  final String hp;
  final String alamat;
  final String password;
  final String fotoKkUrl;
  final String deviceId;

  const RegisterParams({
    required this.nik,
    required this.nama,
    required this.email,
    required this.hp,
    required this.alamat,
    required this.password,
    required this.fotoKkUrl,
    required this.deviceId,
  });

  @override
  List<Object> get props => [nik, nama, email, hp, alamat, password, fotoKkUrl, deviceId];
}
