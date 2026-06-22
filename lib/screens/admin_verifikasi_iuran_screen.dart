import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminVerifikasiIuranScreen extends StatefulWidget {
  const AdminVerifikasiIuranScreen({super.key});

  @override
  State<AdminVerifikasiIuranScreen> createState() => _AdminVerifikasiIuranScreenState();
}

class _AdminVerifikasiIuranScreenState extends State<AdminVerifikasiIuranScreen> {
  final Color primaryTeal = const Color(0xFF0F766E);
  final Color textDark = const Color(0xFF1E293B);
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingPayments();
  }

  Future<void> _fetchPendingPayments() async {
    try {
      final data = await Supabase.instance.client
          .from('pembayaran_iuran')
          .select('*, users(nama_lengkap, alamat)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingPayments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment(Map<String, dynamic> payment, String status) async {
    try {
      final client = Supabase.instance.client;
      final int amount = payment['jumlah_bayar'] ?? 0;

      // 1. Update Status Pembayaran
      await client.from('pembayaran_iuran').update({
        'status': status,
      }).eq('id', payment['id']);

      // 2. Jika Approved, Tambah Saldo di Kas RT
      if (status == 'approved') {
        final kasData = await client.from('kas_rt').select().limit(1).maybeSingle();
        if (kasData != null) {
          final int currentSaldo = kasData['total_saldo'] ?? 0;
          await client.from('kas_rt').update({
            'total_saldo': currentSaldo + amount,
            'last_updated': DateTime.now().toIso8601String(),
          }).eq('id', kasData['id']);
        } else {
          await client.from('kas_rt').insert({
            'total_saldo': amount,
            'is_published': true
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selesai! Status diperbarui.'), backgroundColor: primaryTeal),
        );
        _fetchPendingPayments();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses: $e'), backgroundColor: Colors.red));
    }
  }

  void _showDetailSheet(Map<String, dynamic> p) {
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final monthName = p['bulan'] != null ? months[p['bulan'] - 1] : '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 32),
            const Text('Detail Pembayaran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Konfirmasi iuran warga wilayah RT 03/06', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 32),
            
            // Detail Info
            _buildDetailItem(Icons.person_rounded, 'Nama Warga', p['users']['nama_lengkap'] ?? '-'),
            _buildDetailItem(Icons.calendar_month_rounded, 'Periode Iuran', '$monthName ${p['tahun']}'),
            _buildDetailItem(Icons.payments_rounded, 'Nominal Bayar', 'Rp ${NumberFormat('#,###', 'id_ID').format(p['jumlah_bayar'])}'),
            
            const Spacer(),
            
            // Action: Lihat Bukti
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _showImageDialog(p['bukti_transfer_url']),
                icon: const Icon(Icons.image_search_rounded),
                label: const Text('LIHAT BUKTI TRANSFER', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryTeal,
                  side: BorderSide(color: primaryTeal.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Action: Verifikasi
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { _processPayment(p, 'rejected'); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18)
                    ),
                    child: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () { _processPayment(p, 'approved'); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18)
                    ),
                    child: const Text('VERIFIKASI PEMBAYAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String? url) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32), onPressed: () => Navigator.pop(c)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: url != null 
                ? Image.network(url, fit: BoxFit.contain)
                : Container(height: 200, color: Colors.white, child: const Center(child: Text('Bukti tidak ditemukan'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: primaryTeal, size: 20)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('VERIFIKASI IURAN', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryTeal))
        : RefreshIndicator(
            onRefresh: _fetchPendingPayments,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ANTRIAN VALIDASI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Klik pada data warga untuk memproses verifikasi pembayaran iuran.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                if (_pendingPayments.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('Tidak ada antrian pembayaran.', style: TextStyle(color: Colors.grey, fontSize: 13))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = _pendingPayments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: ListTile(
                              onTap: () => _showDetailSheet(p),
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                                child: Text(p['bulan'].toString(), style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(p['users']['nama_lengkap'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('Rp ${NumberFormat('#,###').format(p['jumlah_bayar'])} • ${p['users']['alamat'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ),
                          );
                        },
                        childCount: _pendingPayments.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}
