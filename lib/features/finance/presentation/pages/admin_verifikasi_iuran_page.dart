import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/finance_entities.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class AdminVerifikasiIuranPage extends StatelessWidget {
  const AdminVerifikasiIuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceBloc>()..add(FetchAdminFinanceData()),
      child: const AdminVerifikasiIuranView(),
    );
  }
}

class AdminVerifikasiIuranView extends StatelessWidget {
  const AdminVerifikasiIuranView({super.key});

  void _showDetailSheet(BuildContext context, PaymentEntity p) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final monthName = months[p.bulan - 1];
    const primaryTeal = Color(0xFF0F766E);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            
            _buildDetailItem(Icons.person_rounded, 'Nama Warga', p.userName ?? '-'),
            _buildDetailItem(Icons.calendar_month_rounded, 'Periode Iuran', '$monthName ${p.tahun}'),
            _buildDetailItem(Icons.payments_rounded, 'Nominal Bayar', 'Rp ${NumberFormat('#,###', 'id_ID').format(p.jumlahBayar)}'),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _showImageDialog(context, p.buktiUrl),
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
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { 
                      context.read<FinanceBloc>().add(UpdatePaymentStatusRequested(p.id, 'rejected'));
                      Navigator.pop(ctx); 
                    },
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
                    onPressed: () { 
                      context.read<FinanceBloc>().add(UpdatePaymentStatusRequested(p.id, 'approved'));
                      Navigator.pop(ctx); 
                    },
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

  void _showImageDialog(BuildContext context, String? url) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(c))),
            if (url != null) Image.network(url) else Container(height: 200, color: Colors.white, child: const Center(child: Text('No image')))
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    const primaryTeal = Color(0xFF0F766E);
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
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('VERIFIKASI IURAN', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is FinanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          List<PaymentEntity> pending = [];
          if (state is AdminFinanceLoaded) {
            pending = state.pendingPayments;
          }

          return CustomScrollView(
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
              if (pending.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('Tidak ada antrian pembayaran.', style: TextStyle(color: Colors.grey, fontSize: 13))))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = pending[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: ListTile(
                            onTap: () => _showDetailSheet(context, p),
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                              child: Text(p.bulan.toString(), style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(p.userName ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Rp ${NumberFormat('#,###').format(p.jumlahBayar)} • ${p.userAddress ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          ),
                        );
                      },
                      childCount: pending.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
