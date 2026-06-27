import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/citizen_repository.dart';
import 'citizen_event.dart';
import 'citizen_state.dart';

class CitizenBloc extends Bloc<CitizenEvent, CitizenState> {
  final CitizenRepository repository;

  CitizenBloc({required this.repository}) : super(CitizenInitial()) {
    on<UpdateCitizenStatusRequested>(_onUpdateCitizenStatusRequested);
    on<ToggleCitizenRoleRequested>(_onToggleCitizenRoleRequested);
    on<ResetCitizenDeviceRequested>(_onResetCitizenDeviceRequested);
  }

  Future<void> _onUpdateCitizenStatusRequested(UpdateCitizenStatusRequested event, Emitter<CitizenState> emit) async {
    emit(CitizenLoading());
    final result = await repository.updateCitizenStatus(event.userId, event.status);
    result.fold(
      (failure) => emit(CitizenFailure(failure.message)),
      (_) => emit(CitizenActionSuccess(event.status == 'approved' ? 'Warga berhasil disetujui!' : 'Pendaftaran ditolak.')),
    );
  }

  Future<void> _onToggleCitizenRoleRequested(ToggleCitizenRoleRequested event, Emitter<CitizenState> emit) async {
    emit(CitizenLoading());
    final result = await repository.toggleCitizenRole(event.userId, event.currentRole);
    result.fold(
      (failure) => emit(CitizenFailure(failure.message)),
      (_) => emit(const CitizenActionSuccess('Role warga berhasil diperbarui')),
    );
  }

  Future<void> _onResetCitizenDeviceRequested(ResetCitizenDeviceRequested event, Emitter<CitizenState> emit) async {
    emit(CitizenLoading());
    final result = await repository.resetCitizenDevice(event.userId);
    result.fold(
      (failure) => emit(CitizenFailure(failure.message)),
      (_) => emit(const CitizenActionSuccess('Gembok HP berhasil di-reset!')),
    );
  }
}
