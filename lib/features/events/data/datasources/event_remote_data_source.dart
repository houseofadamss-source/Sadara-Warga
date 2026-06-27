import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Stream<List<EventModel>> watchAllEvents();
  Future<List<String>> getUserRsvps(String nik);
  Future<void> addRsvp(String eventId, String nik);
  Future<void> removeRsvp(String eventId, String nik);
  Future<void> addEvent(EventModel event);
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String id);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final SupabaseClient client;

  EventRemoteDataSourceImpl(this.client);

  @override
  Stream<List<EventModel>> watchAllEvents() {
    return client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: true)
        .map((list) => EventModel.fromJsonList(list));
  }

  @override
  Future<List<String>> getUserRsvps(String nik) async {
    final response = await client
        .from('event_rsvp')
        .select('event_id')
        .eq('nik', nik);
    return (response as List).map((e) => e['event_id'].toString()).toList();
  }

  @override
  Future<void> addRsvp(String eventId, String nik) async {
    await client.from('event_rsvp').insert({'event_id': eventId, 'nik': nik});
  }

  @override
  Future<void> removeRsvp(String eventId, String nik) async {
    await client.from('event_rsvp').delete().eq('event_id', eventId).eq('nik', nik);
  }

  @override
  Future<void> addEvent(EventModel event) async {
    await client.from('events').insert(event.toJson());
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    await client.from('events').update(event.toJson()).eq('id', event.id);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await client.from('events').delete().eq('id', id);
  }
}
