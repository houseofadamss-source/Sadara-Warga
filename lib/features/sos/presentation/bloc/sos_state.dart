import 'package:equatable/equatable.dart';
import '../../domain/entities/emergency_entity.dart';

abstract class SosState extends Equatable {
  const SosState();
  
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {}

class SosLoading extends SosState {}

class SosLoaded extends SosState {
  final List<EmergencyEntity> contacts;
  const SosLoaded(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

class SosActionSuccess extends SosState {
  final String message;
  const SosActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SosFailure extends SosState {
  final String message;
  const SosFailure(this.message);

  @override
  List<Object?> get props => [message];
}
