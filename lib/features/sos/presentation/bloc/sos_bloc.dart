import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/emergency_repository.dart';
import 'sos_event.dart';
import 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  final EmergencyRepository repository;

  SosBloc({required this.repository}) : super(SosInitial()) {
    on<FetchAllContactsRequested>(_onFetchAllContactsRequested);
    on<SaveContactRequested>(_onSaveContactRequested);
    on<DeleteContactRequested>(_onDeleteContactRequested);
  }

  Future<void> _onFetchAllContactsRequested(FetchAllContactsRequested event, Emitter<SosState> emit) async {
    emit(SosLoading());
    final result = await repository.getAllContacts();
    result.fold(
      (failure) => emit(SosFailure(failure.message)),
      (list) => emit(SosLoaded(list)),
    );
  }

  Future<void> _onSaveContactRequested(SaveContactRequested event, Emitter<SosState> emit) async {
    emit(SosLoading());
    final result = await repository.saveContact(event.contact);
    result.fold(
      (failure) => emit(SosFailure(failure.message)),
      (_) => emit(const SosActionSuccess('Kontak darurat berhasil disimpan')),
    );
  }

  Future<void> _onDeleteContactRequested(DeleteContactRequested event, Emitter<SosState> emit) async {
    emit(SosLoading());
    final result = await repository.deleteContact(event.id);
    result.fold(
      (failure) => emit(SosFailure(failure.message)),
      (_) => emit(const SosActionSuccess('Kontak darurat berhasil dihapus')),
    );
  }
}
