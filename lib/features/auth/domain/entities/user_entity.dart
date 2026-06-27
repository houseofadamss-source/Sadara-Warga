import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String nik;
  final String namaLengkap;
  final String email;
  final String nomorHp;
  final String alamat;
  final String role;
  final String statusAkun;
  final String? fotoProfil;

  const UserEntity({
    required this.id,
    required this.nik,
    required this.namaLengkap,
    required this.email,
    required this.nomorHp,
    required this.alamat,
    required this.role,
    required this.statusAkun,
    this.fotoProfil,
  });

  @override
  List<Object?> get props => [id, nik, namaLengkap, email, nomorHp, alamat, role, statusAkun, fotoProfil];
}
