import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String deviceId;

  const LoginRequested({required this.email, required this.password, required this.deviceId});

  @override
  List<Object> get props => [email, password, deviceId];
}

class RegisterRequested extends AuthEvent {
  final String nik;
  final String nama;
  final String email;
  final String hp;
  final String alamat;
  final String password;
  final String fotoKkUrl;
  final String deviceId;

  const RegisterRequested({
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

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}
