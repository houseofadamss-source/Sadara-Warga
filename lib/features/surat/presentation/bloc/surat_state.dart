import 'package:equatable/equatable.dart';

abstract class SuratState extends Equatable {
  const SuratState();
  
  @override
  List<Object?> get props => [];
}

class SuratInitial extends SuratState {}

class SuratLoading extends SuratState {}

class SuratActionSuccess extends SuratState {
  final String message;
  const SuratActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SuratFailure extends SuratState {
  final String message;
  const SuratFailure(this.message);

  @override
  List<Object?> get props => [message];
}
