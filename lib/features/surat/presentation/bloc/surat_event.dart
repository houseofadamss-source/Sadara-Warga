import 'package:equatable/equatable.dart';
import '../../domain/entities/surat_entity.dart';

abstract class SuratEvent extends Equatable {
  const SuratEvent();

  @override
  List<Object> get props => [];
}

class SubmitSuratRequested extends SuratEvent {
  final SuratEntity surat;
  const SubmitSuratRequested(this.surat);

  @override
  List<Object> get props => [surat];
}

class UpdateSuratStatusRequested extends SuratEvent {
  final String id;
  final String status;
  final String? nomorSurat;

  const UpdateSuratStatusRequested({required this.id, required this.status, this.nomorSurat});

  @override
  List<Object> get props => [id, status, if (nomorSurat != null) nomorSurat!];
}
