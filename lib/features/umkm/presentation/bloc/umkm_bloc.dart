import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/umkm_repository.dart';
import '../../domain/usecases/register_umkm_usecase.dart';
import 'umkm_event.dart';
import 'umkm_state.dart';

class UmkmBloc extends Bloc<UmkmEvent, UmkmState> {
  final UmkmRepository repository;
  final RegisterUmkmUseCase registerUseCase;

  UmkmBloc({
    required this.repository,
    required this.registerUseCase,
  }) : super(UmkmInitial()) {
    on<FetchApprovedUmkm>(_onFetchApprovedUmkm);
    on<RegisterUmkmRequested>(_onRegisterUmkmRequested);
    on<UpdateStatusRequested>(_onUpdateStatusRequested);
    on<ToggleFeaturedRequested>(_onToggleFeaturedRequested);
    on<PushToOsmRequested>(_onPushToOsmRequested);
  }

  Future<void> _onFetchApprovedUmkm(FetchApprovedUmkm event, Emitter<UmkmState> emit) async {
    emit(UmkmLoading());
    final result = await repository.getAllApprovedUmkm();
    result.fold(
      (failure) => emit(UmkmFailure(failure.message)),
      (list) => emit(UmkmLoaded(list)),
    );
  }

  Future<void> _onRegisterUmkmRequested(RegisterUmkmRequested event, Emitter<UmkmState> emit) async {
    emit(UmkmLoading());
    final result = await registerUseCase(event.umkm);
    result.fold(
      (failure) => emit(UmkmFailure(failure.message)),
      (_) => emit(const UmkmActionSuccess('Pendaftaran UMKM berhasil terkirim!')),
    );
  }

  Future<void> _onUpdateStatusRequested(UpdateStatusRequested event, Emitter<UmkmState> emit) async {
    final result = await repository.updateUmkmStatus(event.id, event.status);
    result.fold(
      (failure) => emit(UmkmFailure(failure.message)),
      (_) => emit(UmkmActionSuccess(event.status == 'approved' ? 'UMKM disetujui' : 'UMKM ditolak')),
    );
  }

  Future<void> _onToggleFeaturedRequested(ToggleFeaturedRequested event, Emitter<UmkmState> emit) async {
    final result = await repository.toggleFeatured(event.id, event.currentVal);
    result.fold(
      (failure) => emit(UmkmFailure(failure.message)),
      (_) => emit(const UmkmActionSuccess('Status unggulan diperbarui')),
    );
  }

  Future<void> _onPushToOsmRequested(PushToOsmRequested event, Emitter<UmkmState> emit) async {
    emit(UmkmLoading());
    final result = await repository.pushToOsm(event.umkm);
    result.fold(
      (failure) => emit(UmkmFailure(failure.message)),
      (_) => emit(const UmkmActionSuccess('Berhasil terbit di OpenStreetMap!')),
    );
  }
}
