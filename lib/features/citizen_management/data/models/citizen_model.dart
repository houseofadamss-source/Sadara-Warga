import '../../domain/entities/citizen_entity.dart';

class CitizenModel extends CitizenEntity {
  const CitizenModel({
    required super.id,
    required super.namaLengkap,
    required super.nik,
    super.email,
    super.nomorHp,
    super.alamat,
    super.fotoProfil,
    super.fotoKk,
    required super.role,
    required super.statusAkun,
    super.deviceId,
  });

  factory CitizenModel.fromJson(Map<String, dynamic> json) {
    return CitizenModel(
      id: json['id']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '-',
      nik: json['nik']?.toString() ?? '-',
      email: json['email']?.toString(),
      nomorHp: json['nomor_hp']?.toString(),
      alamat: json['alamat']?.toString(),
      fotoProfil: json['foto_profil']?.toString(),
      fotoKk: json['foto_kk']?.toString(),
      role: json['role']?.toString() ?? 'warga',
      statusAkun: json['status_akun']?.toString() ?? 'pending',
      deviceId: json['device_id']?.toString(),
    );
  }

  static List<CitizenModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => CitizenModel.fromJson(item)).toList();
  }
}
