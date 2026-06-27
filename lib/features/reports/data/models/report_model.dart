import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.userId,
    required super.namaWarga,
    required super.judulLaporan,
    required super.deskripsi,
    required super.kategori,
    super.fotoUrl,
    required super.status,
    super.latitude,
    super.longitude,
    required super.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      namaWarga: json['nama_warga']?.toString() ?? '-',
      judulLaporan: json['judul_laporan']?.toString() ?? '-',
      deskripsi: json['deskripsi']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? 'Umum',
      fotoUrl: json['foto_url']?.toString(),
      status: json['status']?.toString() ?? 'Menunggu',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nama_warga': namaWarga,
      'judul_laporan': judulLaporan,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'foto_url': fotoUrl,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static List<ReportModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => ReportModel.fromJson(item)).toList();
  }
}
