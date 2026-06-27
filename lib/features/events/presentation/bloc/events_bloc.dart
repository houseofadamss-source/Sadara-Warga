import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/event_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventRepository repository;

  EventsBloc({required this.repository}) : super(EventsInitial()) {
    on<FetchEventsRequested>(_onFetchEventsRequested);
    on<ToggleRsvpRequested>(_onToggleRsvpRequested);
    on<AddEventRequested>(_onAddEventRequested);
    on<UpdateEventRequested>(_onUpdateEventRequested);
    on<DeleteEventRequested>(_onDeleteEventRequested);
  }

  Future<void> _onFetchEventsRequested(FetchEventsRequested event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    
    // Logic Fail-Safe: Kalau NIK kosong atau query RSVP gagal, kasih list kosong aja, jangan bikin crash.
    List<String> rsvps = [];
    if (event.userNik.isNotEmpty && event.userNik != '-') {
      final rsvpResult = await repository.getUserRsvps(event.userNik);
      rsvpResult.fold(
        (failure) => debugPrint('RSVP Error (Table might be missing): ${failure.message}'),
        (list) => rsvps = list,
      );
    }
    
    // Tetap dengerin stream event utama
    await emit.forEach(
      repository.watchAllEvents(),
      onData: (events) => EventsLoaded(events: events, userRsvps: rsvps),
      onError: (error, stackTrace) => EventsFailure(error.toString()),
    );
  }

  Future<void> _onToggleRsvpRequested(ToggleRsvpRequested event, Emitter<EventsState> emit) async {
    final result = await repository.toggleRsvp(event.eventId, event.userNik, event.isCurrentlyRsvped);
    
    result.fold(
      (failure) => emit(EventsFailure(failure.message)),
      (_) {
        // Trigger fetch ulang buat sinkronisasi RSVP terbaru
        add(FetchEventsRequested(event.userNik));
      },
    );
  }

  Future<void> _onAddEventRequested(AddEventRequested event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    final result = await repository.addEvent(event.event);
    result.fold(
      (failure) => emit(EventsFailure(failure.message)),
      (_) => emit(const EventsActionSuccess('Acara berhasil diterbitkan')),
    );
  }

  Future<void> _onUpdateEventRequested(UpdateEventRequested event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    final result = await repository.updateEvent(event.event);
    result.fold(
      (failure) => emit(EventsFailure(failure.message)),
      (_) => emit(const EventsActionSuccess('Acara berhasil diperbarui')),
    );
  }

  Future<void> _onDeleteEventRequested(DeleteEventRequested event, Emitter<EventsState> emit) async {
    final result = await repository.deleteEvent(event.id);
    result.fold(
      (failure) => emit(EventsFailure(failure.message)),
      (_) => emit(const EventsActionSuccess('Acara berhasil dihapus')),
    );
  }
}
