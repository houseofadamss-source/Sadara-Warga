import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/announcement_repository.dart';
import 'announcement_event.dart';
import 'announcement_state.dart';

class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository repository;

  AnnouncementBloc({required this.repository}) : super(AnnouncementInitial()) {
    on<FetchAnnouncementsRequested>(_onFetchAnnouncementsRequested);
    on<AddAnnouncementRequested>(_onAddAnnouncementRequested);
    on<UpdateAnnouncementRequested>(_onUpdateAnnouncementRequested);
    on<DeleteAnnouncementRequested>(_onDeleteAnnouncementRequested);
    on<ToggleFeaturedRequested>(_onToggleFeaturedRequested);
  }

  Future<void> _onFetchAnnouncementsRequested(FetchAnnouncementsRequested event, Emitter<AnnouncementState> emit) async {
    emit(AnnouncementLoading());
    final result = await repository.getAllAnnouncements();
    result.fold(
      (failure) => emit(AnnouncementFailure(failure.message)),
      (list) => emit(AnnouncementsLoaded(list.where((e) => e.tipe == event.tipe).toList())),
    );
  }

  Future<void> _onAddAnnouncementRequested(AddAnnouncementRequested event, Emitter<AnnouncementState> emit) async {
    emit(AnnouncementLoading());
    final result = await repository.addAnnouncement(event.announcement);
    result.fold(
      (failure) => emit(AnnouncementFailure(failure.message)),
      (_) => emit(const AnnouncementActionSuccess('Pengumuman berhasil diterbitkan')),
    );
  }

  Future<void> _onUpdateAnnouncementRequested(UpdateAnnouncementRequested event, Emitter<AnnouncementState> emit) async {
    emit(AnnouncementLoading());
    final result = await repository.updateAnnouncement(event.announcement);
    result.fold(
      (failure) => emit(AnnouncementFailure(failure.message)),
      (_) => emit(const AnnouncementActionSuccess('Pengumuman berhasil diperbarui')),
    );
  }

  Future<void> _onDeleteAnnouncementRequested(DeleteAnnouncementRequested event, Emitter<AnnouncementState> emit) async {
    final result = await repository.deleteAnnouncement(event.id);
    result.fold(
      (failure) => emit(AnnouncementFailure(failure.message)),
      (_) => emit(const AnnouncementActionSuccess('Pengumuman berhasil dihapus')),
    );
  }

  Future<void> _onToggleFeaturedRequested(ToggleFeaturedRequested event, Emitter<AnnouncementState> emit) async {
    final result = await repository.toggleFeatured(event.id, event.currentStatus);
    result.fold(
      (failure) => emit(AnnouncementFailure(failure.message)),
      (_) => emit(const AnnouncementActionSuccess('Status unggulan diperbarui')),
    );
  }
}
