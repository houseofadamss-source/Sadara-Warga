import '../../domain/entities/emergency_entity.dart';

class EmergencyModel extends EmergencyEntity {
  const EmergencyModel({
    super.id,
    required super.category,
    required super.actionType,
    required super.phone,
    required super.title,
    required super.description,
    required super.isActive,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'pengurus',
      actionType: json['action_type']?.toString() ?? 'call',
      phone: json['phone']?.toString() ?? '',
      title: json['title']?.toString() ?? '-',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'category': category,
      'action_type': actionType,
      'phone': phone,
      'title': title,
      'description': description,
      'is_active': isActive,
    };
    if (id != null) map['id'] = id as String;
    return map;
  }

  static List<EmergencyModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => EmergencyModel.fromJson(item)).toList();
  }
}
