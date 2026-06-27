import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_model.dart';

abstract class EmergencyRemoteDataSource {
  Stream<List<EmergencyModel>> watchActiveContacts();
  Future<List<EmergencyModel>> getAllContacts();
  Future<void> saveContact(EmergencyModel contact);
  Future<void> deleteContact(String id);
}

class EmergencyRemoteDataSourceImpl implements EmergencyRemoteDataSource {
  final SupabaseClient client;

  EmergencyRemoteDataSourceImpl(this.client);

  @override
  Stream<List<EmergencyModel>> watchActiveContacts() {
    return client
        .from('emergency_contacts')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('category', ascending: true)
        .map((list) => EmergencyModel.fromJsonList(list));
  }

  @override
  Future<List<EmergencyModel>> getAllContacts() async {
    final response = await client
        .from('emergency_contacts')
        .select()
        .order('created_at', ascending: false);
    return EmergencyModel.fromJsonList(response);
  }

  @override
  Future<void> saveContact(EmergencyModel contact) async {
    final data = contact.toJson();
    if (contact.id != null) {
      await client.from('emergency_contacts').update(data).eq('id', contact.id!);
    } else {
      await client.from('emergency_contacts').insert(data);
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    await client.from('emergency_contacts').delete().eq('id', id);
  }
}
