import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String coordinatorName;
  final String coordinatorPhone;
  final String eventDate;
  final String eventTime;
  final String? imageUrl;
  final String status;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.coordinatorName,
    required this.coordinatorPhone,
    required this.eventDate,
    required this.eventTime,
    this.imageUrl,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id, title, description, location, latitude, longitude,
        coordinatorName, coordinatorPhone, eventDate, eventTime,
        imageUrl, status,
      ];
}
