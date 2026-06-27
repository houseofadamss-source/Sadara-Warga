import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadarawarga/features/auth/domain/usecases/login_usecase.dart';
import 'package:sadarawarga/features/auth/domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
      deviceId: event.deviceId,
    ));

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(RegisterParams(
      nik: event.nik,
      nama: event.nama,
      email: event.email,
      hp: event.hp,
      alamat: event.alamat,
      password: event.password,
      fotoKkUrl: event.fotoKkUrl,
      deviceId: event.deviceId,
    ));

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(RegisterSuccess()),
    );
  }
}
