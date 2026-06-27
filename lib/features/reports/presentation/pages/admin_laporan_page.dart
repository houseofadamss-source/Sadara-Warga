import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class AdminLaporanPage extends StatelessWidget {
  const AdminLaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportBloc>(),
      child: const AdminLaporanView(),
    );
  }
}

class AdminLaporanView extends StatelessWidget {
  const AdminLaporanView({super.key});

  void _showReportDetail(BuildContext context, ReportEntity report) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);
    String status = report.status;
    Color statusColor = status == 'Menunggu' ? Colors.orange : status == 'Diproses' ? Colors.blue : Colors.green;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                Text(report.kategori, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            Text(report.judulLaporan, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded, size: 16, color: primaryTeal),
                const SizedBox(width: 8),
                Text(report.namaWarga, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 24),
            const Text('DESKRIPSI KEJADIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.deskripsi, style: const TextStyle(fontSize: 15, color: textDark, height: 1.6)),
                    if (report.fotoUrl != null) ...[
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(report.fotoUrl!, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    if (report.latitude != null && report.longitude != null) ...[
                      const SizedBox(height: 24),
                      const Text('LOKASI KEJADIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${report.latitude},${report.longitude}");
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.map_outlined, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Lihat di Google Maps', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                                    Text('Klik untuk melihat titik lokasi akurat', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  ],
                                ),
                              ),
                              Icon(Icons.open_in_new_rounded, size: 16, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (status != 'Selesai' && status != 'Ditolak')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<ReportBloc>().add(UpdateReportStatusRequested(report.id, status == 'Menunggu' ? 'Diproses' : 'Selesai'));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'Menunggu' ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(status == 'Menunggu' ? 'PROSES LAPORAN' : 'SELESAIKAN LAPORAN', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            if (status == 'Menunggu') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<ReportBloc>().add(UpdateReportStatusRequested(report.id, 'Ditolak'));
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('TOLAK LAPORAN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: true,
        title: const Text('MANAJEMEN LAPORAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is ReportFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: StreamBuilder<List<ReportEntity>>(
          stream: sl<ReportRepository>().watchAllReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryTeal));
            final reports = snapshot.data ?? [];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ADUAN WARGA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                        const SizedBox(height: 8),
                        const Text(
                          'Klik pada kartu laporan untuk melihat detail kejadian dan menindaklanjuti status laporan tersebut.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                if (reports.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Belum ada laporan dari warga', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final report = reports[index];
                          String status = report.status;
                          Color statusColor = status == 'Menunggu' ? Colors.orange : status == 'Diproses' ? Colors.blue : Colors.green;

                          return GestureDetector(
                            onTap: () => _showReportDetail(context, report),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                                    child: Icon(status == 'Selesai' ? Icons.check_circle : Icons.error_outline, color: statusColor, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(report.judulLaporan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('Dari: ${report.namaWarga}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: reports.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}
