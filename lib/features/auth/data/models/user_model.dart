import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nik,
    required super.namaLengkap,
    required super.email,
    required super.nomorHp,
    required super.alamat,
    required super.role,
    required super.statusAkun,
    super.fotoProfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '-',
      namaLengkap: json['nama_lengkap']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      nomorHp: json['nomor_hp']?.toString() ?? '-',
      alamat: json['alamat']?.toString() ?? '-',
      role: json['role']?.toString() ?? 'warga',
      statusAkun: json['status_akun']?.toString() ?? 'pending',
      fotoProfil: json['foto_profil']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'nama_lengkap': namaLengkap,
      'email': email,
      'nomor_hp': nomorHp,
      'alamat': alamat,
      'role': role,
      'status_akun': statusAkun,
      'foto_profil': fotoProfil,
    };
  }
}
