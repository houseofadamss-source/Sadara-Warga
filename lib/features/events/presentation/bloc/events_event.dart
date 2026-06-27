import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object> get props => [];
}

class FetchEventsRequested extends EventsEvent {
  final String userNik;
  const FetchEventsRequested(this.userNik);

  @override
  List<Object> get props => [userNik];
}

class ToggleRsvpRequested extends EventsEvent {
  final String eventId;
  final String userNik;
  final bool isCurrentlyRsvped;

  const ToggleRsvpRequested({
    required this.eventId,
    required this.userNik,
    required this.isCurrentlyRsvped,
  });

  @override
  List<Object> get props => [eventId, userNik, isCurrentlyRsvped];
}

class AddEventRequested extends EventsEvent {
  final EventEntity event;
  const AddEventRequested(this.event);

  @override
  List<Object> get props => [event];
}

class UpdateEventRequested extends EventsEvent {
  final EventEntity event;
  const UpdateEventRequested(this.event);

  @override
  List<Object> get props => [event];
}

class DeleteEventRequested extends EventsEvent {
  final String id;
  const DeleteEventRequested(this.id);

  @override
  List<Object> get props => [id];
}
