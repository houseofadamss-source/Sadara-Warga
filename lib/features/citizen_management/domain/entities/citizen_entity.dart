import 'package:equatable/equatable.dart';

class CitizenEntity extends Equatable {
  final String id;
  final String namaLengkap;
  final String nik;
  final String? email;
  final String? nomorHp;
  final String? alamat;
  final String? fotoProfil;
  final String? fotoKk;
  final String role;
  final String statusAkun;
  final String? deviceId;

  const CitizenEntity({
    required this.id,
    required this.namaLengkap,
    required this.nik,
    this.email,
    this.nomorHp,
    this.alamat,
    this.fotoProfil,
    this.fotoKk,
    required this.role,
    required this.statusAkun,
    this.deviceId,
  });

  @override
  List<Object?> get props => [
    id, namaLengkap, nik, email, nomorHp, alamat, 
    fotoProfil, fotoKk, role, statusAkun, deviceId,
  ];
}
