import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';

class ReportHistoryPage extends StatelessWidget {
  final String nik;
  final VoidCallback onBack;
  const ReportHistoryPage({super.key, required this.nik, required this.onBack});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);
    final userId = sl<SupabaseClient>().auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('AKTIVITAS LAPORAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: onBack,
        ),
      ),
      body: userId.isEmpty 
        ? const Center(child: Text('Silakan login terlebih dahulu.'))
        : StreamBuilder<List<ReportEntity>>(
            stream: sl<ReportRepository>().watchUserReports(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Gagal memuat aktivitas: ${snapshot.error}'));
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryTeal));
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('Belum ada riwayat aktivitas.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final date = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt.toLocal());
                  final String status = report.status.toLowerCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(status),
                            Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.judulLaporan,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                        if (report.fotoUrl != null && report.fotoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              report.fotoUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'selesai':
        color = Colors.green;
        text = 'SELESAI';
        break;
      case 'proses':
      case 'diproses':
        color = Colors.blue;
        text = 'PROSES';
        break;
      case 'ditolak':
        color = Colors.red;
        text = 'DITOLAK';
        break;
      default:
        color = Colors.orange;
        text = 'MENUNGGU';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
