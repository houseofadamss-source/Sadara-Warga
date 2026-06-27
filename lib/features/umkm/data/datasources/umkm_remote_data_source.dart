import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/umkm_model.dart';
import '../../../../services/osm_api_service.dart';

abstract class UmkmRemoteDataSource {
  Stream<List<UmkmModel>> getFeaturedUmkm();
  Future<List<UmkmModel>> getAllApprovedUmkm();
  Stream<List<UmkmModel>> getUmkmByStatus(String status);
  Future<void> registerUmkm(UmkmModel umkm);
  Future<void> updateUmkmStatus(String id, String status);
  Future<void> toggleFeatured(String id, bool currentVal);
  Future<bool> pushToOsm(UmkmModel umkm);
}

class UmkmRemoteDataSourceImpl implements UmkmRemoteDataSource {
  final SupabaseClient client;
  final OsmApiService osmApi;

  UmkmRemoteDataSourceImpl({required this.client, required this.osmApi});

  @override
  Stream<List<UmkmModel>> getFeaturedUmkm() {
    // Supabase Stream only supports ONE filter. We filter 'status' in Dart.
    return client
        .from('umkm')
        .stream(primaryKey: ['id'])
        .eq('is_weekly_featured', true)
        .map((list) => UmkmModel.fromJsonList(
              list.where((element) => element['status'] == 'approved').toList(),
            ));
  }

  @override
  Future<List<UmkmModel>> getAllApprovedUmkm() async {
    final response = await client
        .from('umkm')
        .select()
        .eq('status', 'approved')
        .order('created_at', ascending: false);
    return UmkmModel.fromJsonList(response);
  }

  @override
  Stream<List<UmkmModel>> getUmkmByStatus(String status) {
    return client
        .from('umkm')
        .stream(primaryKey: ['id'])
        .eq('status', status)
        .map((list) => UmkmModel.fromJsonList(list));
  }

  @override
  Future<void> registerUmkm(UmkmModel umkm) async {
    await client.from('umkm').insert(umkm.toJson());
  }

  @override
  Future<void> updateUmkmStatus(String id, String status) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (status == 'approved') {
      updateData['is_weekly_featured'] = false;
    }
    await client.from('umkm').update(updateData).eq('id', id);
  }

  @override
  Future<void> toggleFeatured(String id, bool currentVal) async {
    if (!currentVal) {
      final res = await client.from('umkm').select().eq('is_weekly_featured', true);
      if ((res as List).length >= 5) {
        throw Exception('Maksimal 5 UMKM Unggulan di Beranda!');
      }
    }
    await client.from('umkm').update({'is_weekly_featured': !currentVal}).eq('id', id);
  }

  @override
  Future<bool> pushToOsm(UmkmModel umkm) async {
    final bool ok = await osmApi.pushToOsm(umkm.toJson()..addAll({
      'latitude': umkm.latitude,
      'longitude': umkm.longitude,
    }));
    
    if (ok) {
      await client.from('umkm').update({'is_pushed_to_osm': true}).eq('id', umkm.id);
    }
    return ok;
  }
}
