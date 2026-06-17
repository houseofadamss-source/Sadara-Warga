import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('LAPORAN KEUANGAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('kas_rt').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final kas = snapshot.data!.isEmpty ? null : snapshot.data!.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saldo Card
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryTeal, Color(0xFF0D9488)]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16), SizedBox(width: 8), Text('Total Saldo Kas RT', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                      const SizedBox(height: 12),
                      Text('Rp ${((kas?['total_saldo'] ?? 0) as num).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Link Detail
                if (kas?['google_doc_url'] != null && kas!['google_doc_url'].toString().isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(kas['google_doc_url']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.withValues(alpha: 0.1))),
                      child: const Row(children: [Icon(Icons.description_rounded, color: Colors.blue), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Laporan Detail (Excel/Sheets)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('Klik untuk melihat rincian lengkap', style: TextStyle(fontSize: 11, color: Colors.grey))])), Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blue)]),
                    ),
                  ),
                
                const SizedBox(height: 32),
                const Text('RIWAYAT PENGELUARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 16),
                _buildExpHistory(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('pengeluaran_kas').stream(primaryKey: ['id']).order('tanggal', ascending: false).limit(10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('Belum ada riwayat pengeluaran.'));

        return Column(
          children: items.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.outbox_rounded, color: Colors.red, size: 20)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(e['tanggal'], style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                Text('-Rp ${e['nominal'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )).toList(),
        );
      },
    );
  }
}
