import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement_model.dart';

abstract class AnnouncementRemoteDataSource {
  Stream<List<AnnouncementModel>> getAnnouncements(String tipe);
  Stream<List<AnnouncementModel>> getFeaturedAnnouncements();
  Future<List<AnnouncementModel>> getAllAnnouncements();
  Future<void> addAnnouncement(AnnouncementModel announcement);
  Future<void> updateAnnouncement(AnnouncementModel announcement);
  Future<void> deleteAnnouncement(String id);
  Future<void> toggleFeatured(String id, bool currentStatus);
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  final SupabaseClient client;

  AnnouncementRemoteDataSourceImpl(this.client);

  @override
  Stream<List<AnnouncementModel>> getAnnouncements(String tipe) {
    if (tipe == 'all') {
      return client
          .from('announcements')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((list) => AnnouncementModel.fromJsonList(list));
    }
    
    return client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('tipe', tipe)
        .order('created_at', ascending: false)
        .map((list) => AnnouncementModel.fromJsonList(list));
  }

  @override
  Stream<List<AnnouncementModel>> getFeaturedAnnouncements() {
    return client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('created_at', ascending: false)
        .map((list) => AnnouncementModel.fromJsonList(list));
  }

  @override
  Future<List<AnnouncementModel>> getAllAnnouncements() async {
    final response = await client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    return AnnouncementModel.fromJsonList(response);
  }

  @override
  Future<void> addAnnouncement(AnnouncementModel announcement) async {
    await client.from('announcements').insert(announcement.toJson());
  }

  @override
  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    await client.from('announcements').update(announcement.toJson()).eq('id', announcement.id);
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await client.from('announcements').delete().eq('id', id);
  }

  @override
  Future<void> toggleFeatured(String id, bool currentStatus) async {
    await client.from('announcements').update({'is_featured': !currentStatus}).eq('id', id);
  }
}
