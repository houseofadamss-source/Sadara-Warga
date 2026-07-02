import '../../domain/entities/surat_entity.dart';

class SuratModel extends SuratEntity {
  const SuratModel({
    required super.id,
    required super.userId,
    required super.nik,
    required super.namaLengkap,
    required super.jenisSurat,
    required super.ttl,
    required super.jenisKelamin,
    required super.agama,
    required super.statusPerkawinan,
    required super.pekerjaan,
    required super.tempatTinggal,
    required super.keperluan,
    required super.status,
    super.nomorSurat,
    super.fileUrl,
    super.verificationToken,
    super.kewarganegaraan,
    required super.createdAt,
  });

  factory SuratModel.fromJson(Map<String, dynamic> json) {
    return SuratModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      jenisSurat: json['jenis_surat']?.toString() ?? 'Surat Pengantar',
      ttl: json['ttl']?.toString() ?? '',
      jenisKelamin: json['jenis_kelamin']?.toString() ?? '',
      agama: json['agama']?.toString() ?? '',
      statusPerkawinan: json['status_perkawinan']?.toString() ?? '',
      pekerjaan: json['pekerjaan']?.toString() ?? '',
      tempatTinggal: json['tempat_tinggal']?.toString() ?? '',
      keperluan: json['keperluan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      nomorSurat: json['nomor_surat']?.toString(),
      fileUrl: json['file_url']?.toString(),
      verificationToken: json['verification_token']?.toString(),
      kewarganegaraan: json['kewarganegaraan']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nik': nik,
      'nama_lengkap': namaLengkap,
      'jenis_surat': jenisSurat,
      'ttl': ttl,
      'jenis_kelamin': jenisKelamin,
      'agama': agama,
      'status_perkawinan': statusPerkawinan,
      'pekerjaan': pekerjaan,
      'tempat_tinggal': tempatTinggal,
      'keperluan': keperluan,
      'status': status,
      if (nomorSurat != null) 'nomor_surat': nomorSurat,
      if (fileUrl != null) 'file_url': fileUrl,
      if (verificationToken != null) 'verification_token': verificationToken,
      if (kewarganegaraan != null) 'kewarganegaraan': kewarganegaraan,
    };
  }

  static List<SuratModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => SuratModel.fromJson(item)).toList();
  }
}
