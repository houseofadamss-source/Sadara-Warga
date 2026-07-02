import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/surat_entity.dart';
import '../../domain/repositories/surat_repository.dart';
import '../bloc/surat_bloc.dart';
import '../bloc/surat_event.dart';
import '../bloc/surat_state.dart';

class SuratHistoryPage extends StatelessWidget {
  const SuratHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return BlocProvider(
      create: (_) => sl<SuratBloc>(),
      child: SuratHistoryView(userId: user?.id ?? ''),
    );
  }
}

class SuratHistoryView extends StatefulWidget {
  final String userId;
  const SuratHistoryView({super.key, required this.userId});

  @override
  State<SuratHistoryView> createState() => _SuratHistoryViewState();
}

class _SuratHistoryViewState extends State<SuratHistoryView> {
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('RIWAYAT SURAT',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<SuratEntity>>(
        stream: sl<SuratRepository>().watchUserSurat(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildSuratCard(items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSuratCard(SuratEntity surat) {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time_rounded;
    String statusText = "MENUNGGU";

    if (surat.status == 'approved') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = "DITERBITKAN";
    } else if (surat.status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusText = "DITOLAK";
    }

    final dateStr = DateFormat('dd MMM yyyy').format(surat.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 6),
                    Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Text(surat.jenisSurat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
          const SizedBox(height: 4),
          Text('Keperluan: ${surat.keperluan}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          
          if (surat.nomorSurat != null) ...[
            const SizedBox(height: 12),
            Text('No: ${surat.nomorSurat}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
          ],

          if (surat.status == 'approved') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // 1. Ambil path file
                    final String path = "${surat.userId}/surat_${surat.id}.pdf";
                    
                    // 2. Download bytes filenya langsung dari Storage
                    final bytes = await Supabase.instance.client.storage
                        .from('arsip_surat')
                        .download(path);

                    // 3. Munculin menu Share/Download bawaan sistem
                    await Printing.sharePdf(
                      bytes: bytes, 
                      filename: 'Surat_Pengantar_${surat.namaLengkap.replaceAll(' ', '_')}.pdf',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Gagal mengunduh surat. Pastikan koneksi internet stabil.'),
                      ));
                    }
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('DOWNLOAD / BAGIKAN SURAT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Belum ada riwayat pengajuan surat.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
