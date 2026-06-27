import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import 'pay_iuran_page.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class FinancePage extends StatelessWidget {
  final String userNik;
  final String userRole;
  const FinancePage({super.key, required this.userNik, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return BlocProvider(
      create: (_) => sl<FinanceBloc>()..add(FetchUserFinanceData(user?.id ?? '')),
      child: FinanceView(userNik: userNik, userRole: userRole),
    );
  }
}

class FinanceView extends StatefulWidget {
  final String userNik;
  final String userRole;
  const FinanceView({super.key, required this.userNik, required this.userRole});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color textDark = Color(0xFF1E293B);

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
        title: const Text('DOMPET WARGA',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
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
    return StreamBuilder<KasEntity>(
      stream: sl<FinanceRepository>().watchKasStatus(),
      builder: (context, snapshot) {
        final nominal = snapshot.data?.totalSaldo ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Column(
            children: [
              const Text('TOTAL SALDO KAS RT',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                  Text('Dana Terverifikasi Transparan',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyIuranTab() {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        if (state is FinanceLoading) {
          return const Center(child: CircularProgressIndicator(color: primaryTeal));
        }

        if (state is UserFinanceLoaded) {
          final pendingBills = state.activeBills.where((b) => !b.isLunas).toList();
          final history = state.paymentHistory;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.notification_important_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      const Text('TAGIHAN AKTIF BULAN INI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
              if (pendingBills.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('✅ Semua tagihan bulan ini sudah dilunasi.',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
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
                  child: const Text('RIWAYAT PEMBAYARAN ANDA',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                ),
              ),
              if (history.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState('Belum ada riwayat pembayaran.'))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final sortedPayments = [...history];
                        sortedPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        final p = sortedPayments[index];
                        
                        final bill = state.activeBills.firstWhere((b) => b.id == p.kategoriId, 
                          orElse: () => BillEntity(id: p.kategoriId, namaIuran: 'Iuran Warga', nominal: 0, isActive: true));

                        return _buildPaymentTile(p, bill.namaIuran);
                      },
                      childCount: history.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildActiveBillCard(BillEntity bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.namaIuran, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                if (bill.totalPaid > 0)
                  Text(
                      'Tercicil: Rp ${NumberFormat('#,###').format(bill.totalPaid)} / Rp ${NumberFormat('#,###').format(bill.nominal)}',
                      style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))
                else
                  Text('Nominal: Rp ${NumberFormat('#,###').format(bill.nominal)}',
                      style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => PayIuranPage(
                 config: {
                   'id': bill.id,
                   'nama_iuran': bill.namaIuran,
                   'nominal': bill.nominal,
                   'total_paid': bill.totalPaid,
                 }
               )));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(bill.totalPaid > 0 ? 'CICIL' : 'BAYAR',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(PaymentEntity p, String kategoriName) {
    final status = p.status;
    Color statusCol = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);

    final dateStr = DateFormat('dd MMM yyyy').format(p.createdAt.toLocal());
    final timeStr = DateFormat('HH:mm').format(p.createdAt.toLocal());

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
            decoration: BoxDecoration(color: statusCol.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(status == 'approved' ? Icons.check_circle_rounded : Icons.history_toggle_off_rounded,
                color: statusCol, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kategoriName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Periode: ${_getMonthName(p.bulan)} ${p.tahun}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
              Text('Rp ${NumberFormat('#,###').format(p.jumlahBayar)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14, color: status == 'approved' ? Colors.green : textDark)),
              const SizedBox(height: 4),
              Text(status.toUpperCase(),
                  style: TextStyle(color: statusCol, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTransparencyTab() {
    return StreamBuilder<KasEntity>(
      stream: sl<FinanceRepository>().watchKasStatus(),
      builder: (context, snapshotKas) {
        return StreamBuilder<List<ExpenseEntity>>(
          stream: sl<FinanceRepository>().watchExpenses(),
          builder: (context, snapshotExps) {
            if (snapshotExps.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final expenses = snapshotExps.data ?? [];
            final kas = snapshotKas.data;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (kas?.googleDocUrl != null && kas!.googleDocUrl!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(kas.googleDocUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.blue.withOpacity(0.1))),
                      child: const Row(children: [
                        Icon(Icons.description_rounded, color: Colors.blue),
                        SizedBox(width: 16),
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Laporan Detail (Excel/Sheets)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Klik untuk melihat rincian lengkap', style: TextStyle(fontSize: 11, color: Colors.grey))
                        ])),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blue)
                      ]),
                    ),
                  ),
                ],
                const Text('RIWAYAT PENGELUARAN RT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 16),
                if (expenses.isEmpty)
                  _buildEmptyState('Belum ada data pengeluaran RT.')
                else
                  ...expenses.map((e) {
                    final date = DateFormat('dd MMM yyyy').format(e.tanggal);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration:
                                BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.outbox_rounded, color: Colors.red, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.judul,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Text('-Rp ${NumberFormat('#,###').format(e.nominal)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red)),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 100),
              ],
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
