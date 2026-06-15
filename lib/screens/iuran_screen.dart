import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'bayar_iuran_screen.dart';

class IuranScreen extends StatefulWidget {
  final String userNik;
  final String userRole;
  const IuranScreen({super.key, required this.userNik, required this.userRole});

  @override
  State<IuranScreen> createState() => _IuranScreenState();
}

class _IuranScreenState extends State<IuranScreen> {
  final Color primaryTeal = const Color(0xFF0F766E);
  bool _isLoading = true;
  List<Map<String, dynamic>> _myPayments = [];
  Map<String, dynamic>? _iuranConfig;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Ambil config iuran (nominal dll)
      final configData = await Supabase.instance.client
          .from('iuran_kategori')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      // 2. Ambil riwayat pembayaran user ini
      final user = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('nik', widget.userNik)
          .single();
      
      final userId = user['id'];

      final paymentsData = await Supabase.instance.client
          .from('pembayaran_iuran')
          .select('*, iuran_kategori(nama_iuran)')
          .eq('user_id', userId)
          .order('tahun', ascending: false)
          .order('bulan', ascending: false);

      if (mounted) {
        setState(() {
          _iuranConfig = configData;
          _myPayments = List<Map<String, dynamic>>.from(paymentsData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error fetch iuran: $e');
    }
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('IURAN WARGA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 32),
                  const Text('RIWAYAT PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  _myPayments.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myPayments.length,
                        itemBuilder: (context, index) {
                          final p = _myPayments[index];
                          return _buildPaymentTile(p);
                        },
                      ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
      floatingActionButton: widget.userRole == 'super_admin' ? null : FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (c) => BayarIuranScreen(userNik: widget.userNik, config: _iuranConfig!)));
          if (res == true) _fetchData();
        },
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add_card_rounded, color: Colors.white),
        label: const Text('BAYAR IURAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final nominal = _iuranConfig?['nominal'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryTeal, const Color(0xFF0D9488)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Iuran Bulanan Aktif', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_iuranConfig?['nama_iuran'] ?? 'Iuran Belum Diatur', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nominal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('Rp ${NumberFormat('#,###').format(nominal)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              if (widget.userRole == 'super_admin')
                ElevatedButton(
                  onPressed: () {
                    // TODO: Menu Kelola buat Admin (Verifikasi bukti bayar)
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('VERIFIKASI WARGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> p) {
    final status = p['status'] ?? 'pending';
    Color statusCol = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    String statusText = status == 'approved' ? 'LUNAS' : (status == 'rejected' ? 'DITOLAK' : 'MENUNGGU');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusCol.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(status == 'approved' ? Icons.check_circle_rounded : Icons.history_toggle_off_rounded, color: statusCol, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_getMonthName(p['bulan'])} ${p['tahun']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Dibayar pd ${DateFormat('dd MMM yyyy').format(DateTime.parse(p['created_at']).toLocal())}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp ${NumberFormat('#,###').format(p['jumlah_bayar'])}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusCol, borderRadius: BorderRadius.circular(6)),
                child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Belum ada riwayat pembayaran.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
