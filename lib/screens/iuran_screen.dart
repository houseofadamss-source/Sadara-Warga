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

class _IuranScreenState extends State<IuranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryTeal = const Color(0xFF0F766E);
  final Color textDark = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('DOMPET WARGA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'IURAN SAYA'),
            Tab(text: 'ARUS KAS RT'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummarySection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyIuranTab(),
                _buildTransparencyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('kas_rt').stream(primaryKey: ['id']).limit(1),
      builder: (context, snapshot) {
        final data = snapshot.data?.isNotEmpty == true ? snapshot.data![0] : {'total_saldo': 0};
        final nominal = data['total_saldo'] ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Column(
            children: [
              const Text('TOTAL SALDO KAS RT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(nominal)}',
                style: TextStyle(color: textDark, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text('Dana Terverifikasi Transparan', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyIuranTab() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Center(child: Text('Login diperlukan.'));
    final now = DateTime.now();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('iuran_kategori').stream(primaryKey: ['id']).eq('is_active', true),
      builder: (context, snapshotBills) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client.from('pembayaran_iuran').stream(primaryKey: ['id']).eq('user_id', user.id),
          builder: (context, snapshotMyPayments) {
            final allBills = snapshotBills.data ?? [];
            final myPayments = snapshotMyPayments.data ?? [];

            final activeBillsWithProgress = allBills.map((bill) {
              final int billNominal = bill['nominal'] as int? ?? 0;
              final int totalPaidForThisBill = myPayments
                  .where((p) => 
                    p['kategori_id'] == bill['id'] && 
                    p['bulan'] == now.month && 
                    p['tahun'] == now.year && 
                    (p['status'] == 'approved' || p['status'] == 'pending')
                  )
                  .fold<int>(0, (sum, p) => sum + (p['jumlah_bayar'] as int? ?? 0));
              
              final int sisa = billNominal - totalPaidForThisBill;
              return {
                ...bill,
                'total_paid': totalPaidForThisBill,
                'sisa': sisa > 0 ? sisa : 0,
                'is_lunas': totalPaidForThisBill >= billNominal,
              };
            }).toList();

            final pendingBills = activeBillsWithProgress.where((b) => !(b['is_lunas'] as bool)).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.notification_important_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        const Text('TAGIHAN AKTIF BULAN INI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
                if (pendingBills.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('✅ Semua tagihan bulan ini sudah dilunasi.', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildActiveBillCard(pendingBills[index]),
                        childCount: pendingBills.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: const Text('RIWAYAT PEMBAYARAN ANDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                  ),
                ),
                if (myPayments.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState('Belum ada riwayat pembayaran.'))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sortedPayments = [...myPayments];
                          sortedPayments.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
                          
                          final p = sortedPayments[index];
                          // Cari nama kategori dari list master iuran (bisa lewat join atau manual find di sini)
                          final kategori = allBills.firstWhere((b) => b['id'] == p['kategori_id'], orElse: () => {'nama_iuran': 'Iuran Warga'});
                          
                          return _buildPaymentTile(p, kategori['nama_iuran']);
                        },
                        childCount: myPayments.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActiveBillCard(Map<String, dynamic> bill) {
    final int totalPaid = bill['total_paid'] ?? 0;
    final int nominal = bill['nominal'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill['nama_iuran'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                if (totalPaid > 0)
                  Text('Tercicil: Rp ${NumberFormat('#,###').format(totalPaid)} / Rp ${NumberFormat('#,###').format(nominal)}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))
                else
                  Text('Nominal: Rp ${NumberFormat('#,###').format(nominal)}', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => BayarIuranScreen(userNik: widget.userNik, config: bill))),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(totalPaid > 0 ? 'CICIL' : 'BAYAR', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> p, String kategoriName) {
    final status = p['status'] ?? 'pending';
    Color statusCol = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    
    // Format tanggal dan jam
    final createdAt = DateTime.parse(p['created_at']).toLocal();
    final dateStr = DateFormat('dd MMM yyyy').format(createdAt);
    final timeStr = DateFormat('HH:mm').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusCol.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(status == 'approved' ? Icons.check_circle_rounded : Icons.history_toggle_off_rounded, color: statusCol, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kategoriName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Periode: ${_getMonthName(p['bulan'])} ${p['tahun']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 10, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$dateStr • $timeStr WIB', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp ${NumberFormat('#,###').format(p['jumlah_bayar'])}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: status == 'approved' ? Colors.green : textDark)),
              const SizedBox(height: 4),
              Text(status.toUpperCase(), style: TextStyle(color: statusCol, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTransparencyTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('pengeluaran_kas').stream(primaryKey: ['id']).order('tanggal_pengeluaran', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) return _buildEmptyState('Belum ada data pengeluaran RT.');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index];
            final date = DateFormat('dd MMM yyyy').format(DateTime.parse(e['tanggal_pengeluaran']));

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.outbox_rounded, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['judul_pengeluaran'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Text('-Rp ${NumberFormat('#,###').format(e['nominal'])}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
