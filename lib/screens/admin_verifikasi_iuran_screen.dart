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
          .select('*, users(nama_lengkap, blok_rumah, nomor_rumah)')
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

  Future<void> _processPayment(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('pembayaran_iuran')
          .update({'status': status, 'verified_at': DateTime.now().toIso8601String()})
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran berhasil di-${status == 'approved' ? 'setujui' : 'tolak'}'), backgroundColor: primaryTeal),
        );
        _fetchPendingPayments();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _showDetailDialog(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Detail Bukti Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p['bukti_bay_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(p['bukti_bay_url'], height: 250, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            Text('Nama: ${p['users']['nama_lengkap']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Alamat: Blok ${p['users']['blok_rumah']} No ${p['users']['nomor_rumah']}'),
            Text('Periode: ${p['bulan']}/${p['tahun']}'),
            Text('Jumlah: Rp ${NumberFormat('#,###').format(p['jumlah_bayar'])}', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('BATAL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { _processPayment(p['id'], 'rejected'); Navigator.pop(c); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red, elevation: 0),
            child: const Text('TOLAK'),
          ),
          ElevatedButton(
            onPressed: () { _processPayment(p['id'], 'approved'); Navigator.pop(c); },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, elevation: 0),
            child: const Text('SETUJUI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: true,
        title: const Text('VERIFIKASI IURAN', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryTeal))
        : RefreshIndicator(
            onRefresh: _fetchPendingPayments,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VALIDASI PEMBAYARAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                        const SizedBox(height: 8),
                        Text(
                          'Periksa kesesuaian bukti transfer warga. Pastikan nominal dan bulan iuran sudah benar sebelum menekan tombol setujui.',
                          style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_pendingPayments.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Tidak ada pembayaran yang perlu diverifikasi.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = _pendingPayments[index];
                          return _buildVerificationCard(p);
                        },
                        childCount: _pendingPayments.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryTeal.withValues(alpha: 0.1),
            child: Text(p['bulan'].toString(), style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['users']['nama_lengkap'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Blok ${p['users']['blok_rumah']} / Rp ${NumberFormat('#,###').format(p['jumlah_bayar'])}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showDetailDialog(p),
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
            child: const Text('CEK BUKTI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
