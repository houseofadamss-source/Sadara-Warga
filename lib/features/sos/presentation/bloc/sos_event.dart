import 'package:equatable/equatable.dart';
import '../../domain/entities/emergency_entity.dart';

abstract class SosEvent extends Equatable {
  const SosEvent();

  @override
  List<Object> get props => [];
}

class FetchAllContactsRequested extends SosEvent {}

class SaveContactRequested extends SosEvent {
  final EmergencyEntity contact;
  const SaveContactRequested(this.contact);

  @override
  List<Object> get props => [contact];
}

class DeleteContactRequested extends SosEvent {
  final String id;
  const DeleteContactRequested(this.id);

  @override
  List<Object> get props => [id];
}
