import 'package:equatable/equatable.dart';

class SuratEntity extends Equatable {
  final String id;
  final String userId;
  final String nik;
  final String namaLengkap;
  final String ttl;
  final String jenisKelamin;
  final String agama;
  final String statusPerkawinan;
  final String pekerjaan;
  final String tempatTinggal;
  final String keperluan;
  final String status;
  final String? nomorSurat;
  final DateTime createdAt;

  const SuratEntity({
    required this.id,
    required this.userId,
    required this.nik,
    required this.namaLengkap,
    required this.ttl,
    required this.jenisKelamin,
    required this.agama,
    required this.statusPerkawinan,
    required this.pekerjaan,
    required this.tempatTinggal,
    required this.keperluan,
    required this.status,
    this.nomorSurat,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, userId, nik, namaLengkap, ttl, jenisKelamin, agama,
    statusPerkawinan, pekerjaan, tempatTinggal, keperluan,
    status, nomorSurat, createdAt,
  ];
}
