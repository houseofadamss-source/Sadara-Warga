import 'package:equatable/equatable.dart';

class UmkmEntity extends Equatable {
  final String id;
  final String userId;
  final String namaBisnis;
  final String jenisDagangan;
  final String produkUtama;
  final String nomorWa;
  final String deskripsi;
  final String jamBuka;
  final String jamTutup;
  final String hariLibur;
  final String? fotoUrl;
  final double latitude;
  final double longitude;
  final String status;
  final bool isWeeklyFeatured;
  final bool isPushedToOsm;

  const UmkmEntity({
    required this.id,
    required this.userId,
    required this.namaBisnis,
    required this.jenisDagangan,
    required this.produkUtama,
    required this.nomorWa,
    required this.deskripsi,
    required this.jamBuka,
    required this.jamTutup,
    required this.hariLibur,
    this.fotoUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isWeeklyFeatured,
    required this.isPushedToOsm,
  });

  @override
  List<Object?> get props => [
        id, userId, namaBisnis, jenisDagangan, produkUtama, nomorWa, 
        deskripsi, jamBuka, jamTutup, hariLibur, fotoUrl, 
        latitude, longitude, status, isWeeklyFeatured, isPushedToOsm
      ];
}
