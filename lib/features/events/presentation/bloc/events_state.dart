import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

abstract class EventsState extends Equatable {
  const EventsState();
  
  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<EventEntity> events;
  final List<String> userRsvps;
  const EventsLoaded({required this.events, required this.userRsvps});

  @override
  List<Object?> get props => [events, userRsvps];
}

class EventsActionSuccess extends EventsState {
  final String message;
  const EventsActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class EventsFailure extends EventsState {
  final String message;
  const EventsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
