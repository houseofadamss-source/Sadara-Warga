import 'package:equatable/equatable.dart';

abstract class CitizenEvent extends Equatable {
  const CitizenEvent();

  @override
  List<Object> get props => [];
}

class UpdateCitizenStatusRequested extends CitizenEvent {
  final String userId;
  final String status;
  const UpdateCitizenStatusRequested(this.userId, this.status);

  @override
  List<Object> get props => [userId, status];
}

class ToggleCitizenRoleRequested extends CitizenEvent {
  final String userId;
  final String currentRole;
  const ToggleCitizenRoleRequested(this.userId, this.currentRole);

  @override
  List<Object> get props => [userId, currentRole];
}

class ResetCitizenDeviceRequested extends CitizenEvent {
  final String userId;
  const ResetCitizenDeviceRequested(this.userId);

  @override
  List<Object> get props => [userId];
}
