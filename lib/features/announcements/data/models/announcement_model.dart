import '../../domain/entities/announcement_entity.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.judul,
    required super.konten,
    super.subJudul,
    super.fileUrl,
    required super.tipe,
    required super.isFeatured,
    required super.createdAt,
    required super.authorId,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'].toString(),
      judul: json['judul'] ?? '-',
      konten: json['konten'] ?? '',
      subJudul: json['sub_judul'],
      fileUrl: json['file_url'],
      tipe: json['tipe'] ?? 'kabar',
      isFeatured: json['is_featured'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      authorId: json['author_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'judul': judul,
      'konten': konten,
      'sub_judul': subJudul,
      'file_url': fileUrl,
      'tipe': tipe,
      'is_featured': isFeatured,
      'author_id': authorId,
    };
  }

  static List<AnnouncementModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => AnnouncementModel.fromJson(item)).toList();
  }
}
