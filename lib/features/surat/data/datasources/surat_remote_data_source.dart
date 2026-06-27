import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/surat_model.dart';

abstract class SuratRemoteDataSource {
  Stream<List<SuratModel>> watchUserSurat(String userId);
  Stream<List<SuratModel>> watchAllSurat(String status);
  Future<void> submitSurat(SuratModel surat);
  Future<void> updateSuratStatus(String id, String status, String? nomorSurat);
}

class SuratRemoteDataSourceImpl implements SuratRemoteDataSource {
  final SupabaseClient client;

  SuratRemoteDataSourceImpl(this.client);

  @override
  Stream<List<SuratModel>> watchUserSurat(String userId) {
    return client
        .from('surat_pengantar')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) => SuratModel.fromJsonList(list));
  }

  @override
  Stream<List<SuratModel>> watchAllSurat(String status) {
    return client
        .from('surat_pengantar')
        .stream(primaryKey: ['id'])
        .eq('status', status)
        .order('created_at', ascending: false)
        .map((list) => SuratModel.fromJsonList(list));
  }

  @override
  Future<void> submitSurat(SuratModel surat) async {
    await client.from('surat_pengantar').insert(surat.toJson());
  }

  @override
  Future<void> updateSuratStatus(String id, String status, String? nomorSurat) async {
    final Map<String, dynamic> data = {'status': status};
    if (nomorSurat != null) data['nomor_surat'] = nomorSurat;
    await client.from('surat_pengantar').update(data).eq('id', id);
  }
}
