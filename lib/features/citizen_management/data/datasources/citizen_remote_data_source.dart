import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/citizen_model.dart';

abstract class CitizenRemoteDataSource {
  Stream<List<CitizenModel>> watchCitizens(String status);
  Future<void> updateCitizenStatus(String userId, String status);
  Future<void> updateCitizenRole(String userId, String newRole);
  Future<void> resetCitizenDevice(String userId);
}

class CitizenRemoteDataSourceImpl implements CitizenRemoteDataSource {
  final SupabaseClient client;

  CitizenRemoteDataSourceImpl(this.client);

  @override
  Stream<List<CitizenModel>> watchCitizens(String status) {
    return client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('status_akun', status)
        .order('nama_lengkap')
        .map((list) => CitizenModel.fromJsonList(list));
  }

  @override
  Future<void> updateCitizenStatus(String userId, String status) async {
    await client.from('users').update({'status_akun': status}).eq('id', userId);
  }

  @override
  Future<void> updateCitizenRole(String userId, String newRole) async {
    await client.from('users').update({'role': newRole}).eq('id', userId);
  }

  @override
  Future<void> resetCitizenDevice(String userId) async {
    await client.from('users').update({'device_id': null}).eq('id', userId);
  }
}
