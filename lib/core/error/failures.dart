import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Kegagalan koneksi ke Server/Supabase
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Kegagalan autentikasi (Sandi salah, dsb)
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// Kegagalan memori lokal
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
