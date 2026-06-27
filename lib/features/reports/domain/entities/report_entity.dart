import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final String id;
  final String userId;
  final String namaWarga;
  final String judulLaporan;
  final String deskripsi;
  final String kategori;
  final String? fotoUrl;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const ReportEntity({
    required this.id,
    required this.userId,
    required this.namaWarga,
    required this.judulLaporan,
    required this.deskripsi,
    required this.kategori,
    this.fotoUrl,
    required this.status,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, userId, namaWarga, judulLaporan, deskripsi, kategori,
    fotoUrl, status, latitude, longitude, createdAt,
  ];
}
