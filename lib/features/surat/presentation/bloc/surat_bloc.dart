import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/surat_repository.dart';
import 'surat_event.dart';
import 'surat_state.dart';

class SuratBloc extends Bloc<SuratEvent, SuratState> {
  final SuratRepository repository;

  SuratBloc({required this.repository}) : super(SuratInitial()) {
    on<SubmitSuratRequested>(_onSubmitSuratRequested);
    on<UpdateSuratStatusRequested>(_onUpdateSuratStatusRequested);
  }

  Future<void> _onSubmitSuratRequested(SubmitSuratRequested event, Emitter<SuratState> emit) async {
    emit(SuratLoading());
    final result = await repository.submitSurat(event.surat);
    result.fold(
      (failure) => emit(SuratFailure(failure.message)),
      (_) => emit(const SuratActionSuccess('Pengajuan surat berhasil dikirim!')),
    );
  }

  Future<void> _onUpdateSuratStatusRequested(UpdateSuratStatusRequested event, Emitter<SuratState> emit) async {
    emit(SuratLoading());
    final result = await repository.updateSuratStatus(event.id, event.status, event.nomorSurat);
    result.fold(
      (failure) => emit(SuratFailure(failure.message)),
      (_) => emit(const SuratActionSuccess('Status surat berhasil diperbarui')),
    );
  }
}
