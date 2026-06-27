import 'package:equatable/equatable.dart';

class EmergencyEntity extends Equatable {
  final String? id;
  final String category;
  final String actionType;
  final String phone;
  final String title;
  final String description;
  final bool isActive;

  const EmergencyEntity({
    this.id,
    required this.category,
    required this.actionType,
    required this.phone,
    required this.title,
    required this.description,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, category, actionType, phone, title, description, isActive];
}
