import 'package:equatable/equatable.dart';

abstract class CitizenState extends Equatable {
  const CitizenState();
  
  @override
  List<Object?> get props => [];
}

class CitizenInitial extends CitizenState {}

class CitizenLoading extends CitizenState {}

class CitizenActionSuccess extends CitizenState {
  final String message;
  const CitizenActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CitizenFailure extends CitizenState {
  final String message;
  const CitizenFailure(this.message);

  @override
  List<Object?> get props => [message];
}
