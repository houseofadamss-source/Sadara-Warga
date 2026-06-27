import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Stream<List<ReportModel>> watchUserReports(String userId);
  Stream<List<ReportModel>> watchAllReports();
  Future<void> submitReport(ReportModel report, String? localImagePath);
  Future<void> updateReportStatus(String id, String newStatus);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final SupabaseClient client;

  ReportRemoteDataSourceImpl(this.client);

  @override
  Stream<List<ReportModel>> watchUserReports(String userId) {
    return client
        .from('reports')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) => ReportModel.fromJsonList(list));
  }

  @override
  Stream<List<ReportModel>> watchAllReports() {
    return client
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => ReportModel.fromJsonList(list));
  }

  @override
  Future<void> submitReport(ReportModel report, String? localImagePath) async {
    String? publicUrl = report.fotoUrl;

    if (localImagePath != null) {
      final fileName = 'report_${report.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from('berkas_warga').upload('reports/$fileName', File(localImagePath));
      publicUrl = client.storage.from('berkas_warga').getPublicUrl('reports/$fileName');
    }

    final data = report.toJson();
    data['foto_url'] = publicUrl;

    await client.from('reports').insert(data);
  }

  @override
  Future<void> updateReportStatus(String id, String newStatus) async {
    await client.from('reports').update({'status': newStatus}).eq('id', id);
  }
}
