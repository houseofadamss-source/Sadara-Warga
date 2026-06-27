import 'package:equatable/equatable.dart';

class AnnouncementEntity extends Equatable {
  final String id;
  final String judul;
  final String konten;
  final String? subJudul;
  final String? fileUrl;
  final String tipe;
  final bool isFeatured;
  final DateTime createdAt;
  final String authorId;

  const AnnouncementEntity({
    required this.id,
    required this.judul,
    required this.konten,
    this.subJudul,
    this.fileUrl,
    required this.tipe,
    required this.isFeatured,
    required this.createdAt,
    required this.authorId,
  });

  @override
  List<Object?> get props => [id, judul, konten, subJudul, fileUrl, tipe, isFeatured, createdAt, authorId];
}
