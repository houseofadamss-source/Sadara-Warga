import '../../domain/entities/umkm_entity.dart';

class UmkmModel extends UmkmEntity {
  const UmkmModel({
    required super.id,
    required super.userId,
    required super.namaBisnis,
    required super.jenisDagangan,
    required super.produkUtama,
    required super.nomorWa,
    required super.deskripsi,
    required super.jamBuka,
    required super.jamTutup,
    required super.hariLibur,
    super.fotoUrl,
    required super.latitude,
    required super.longitude,
    required super.status,
    required super.isWeeklyFeatured,
    required super.isPushedToOsm,
  });

  factory UmkmModel.fromJson(Map<String, dynamic> json) {
    return UmkmModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      namaBisnis: json['nama_bisnis']?.toString() ?? '-',
      jenisDagangan: json['jenis_dagangan']?.toString() ?? '-',
      produkUtama: json['produk_utama']?.toString() ?? '-',
      nomorWa: json['nomor_wa']?.toString() ?? '-',
      deskripsi: json['deskripsi']?.toString() ?? '',
      jamBuka: json['jam_buka']?.toString() ?? '08:00',
      jamTutup: json['jam_tutup']?.toString() ?? '21:00',
      hariLibur: json['hari_libur']?.toString() ?? 'Buka Setiap Hari',
      fotoUrl: json['foto_url']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      isWeeklyFeatured: json['is_weekly_featured'] ?? false,
      isPushedToOsm: json['is_pushed_to_osm'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nama_bisnis': namaBisnis,
      'jenis_dagangan': jenisDagangan,
      'produk_utama': produkUtama,
      'nomor_wa': nomorWa,
      'deskripsi': deskripsi,
      'jam_buka': jamBuka,
      'jam_tutup': jamTutup,
      'hari_libur': hariLibur,
      'foto_url': fotoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  static List<UmkmModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => UmkmModel.fromJson(item)).toList();
  }
}
