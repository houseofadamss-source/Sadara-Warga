import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.location,
    required super.latitude,
    required super.longitude,
    required super.coordinatorName,
    required super.coordinatorPhone,
    required super.eventDate,
    required super.eventTime,
    super.imageUrl,
    required super.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'].toString(),
      title: json['title'] ?? '-',
      description: json['description'] ?? '',
      location: json['location'] ?? '-',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      coordinatorName: json['coordinator_name'] ?? '-',
      coordinatorPhone: json['coordinator_phone'] ?? '-',
      eventDate: json['event_date'] ?? '',
      eventTime: json['event_time'] ?? '',
      imageUrl: json['image_url'],
      status: json['status'] ?? 'aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'coordinator_name': coordinatorName,
      'coordinator_phone': coordinatorPhone,
      'event_date': eventDate,
      'event_time': eventTime,
      'image_url': imageUrl,
      'status': status,
    };
  }

  static List<EventModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => EventModel.fromJson(item)).toList();
  }
}
