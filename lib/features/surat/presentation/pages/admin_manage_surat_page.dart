import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/surat_entity.dart';
import '../../domain/repositories/surat_repository.dart';
import '../bloc/surat_bloc.dart';
import '../bloc/surat_event.dart';
import '../bloc/surat_state.dart';

class AdminManageSuratPage extends StatelessWidget {
  const AdminManageSuratPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SuratBloc>(),
      child: const AdminManageSuratView(),
    );
  }
}

class AdminManageSuratView extends StatefulWidget {
  const AdminManageSuratView({super.key});

  @override
  State<AdminManageSuratView> createState() => _AdminManageSuratViewState();
}

class _AdminManageSuratViewState extends State<AdminManageSuratView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noSuratCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noSuratCtrl.dispose();
    super.dispose();
  }

  void _showProcessModal(BuildContext context, SuratEntity surat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text('Proses Surat Pengantar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Pemohon: ${surat.namaLengkap}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            const Text('INPUT NOMOR SURAT RESMI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _noSuratCtrl,
              decoration: InputDecoration(
                hintText: 'Misal: 001/SP/RT03/VI/2026', 
                filled: true, fillColor: const Color(0xFFF8FAFC), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F766E))),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SuratBloc>().add(UpdateSuratStatusRequested(id: surat.id, status: 'approved', nomorSurat: _noSuratCtrl.text.trim()));
                  _noSuratCtrl.clear();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text('SETUJUI & TERBITKAN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('MANAJEMEN SURAT', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal, unselectedLabelColor: const Color(0xFF94A3B8), indicatorColor: primaryTeal, indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [Tab(text: 'ANTRIAN MASUK'), Tab(text: 'SURAT SELESAI')],
        ),
      ),
      body: BlocListener<SuratBloc, SuratState>(
        listener: (context, state) {
          if (state is SuratActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is SuratFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [_buildList('pending'), _buildList('approved')],
        ),
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<List<SuratEntity>>(
      stream: sl<SuratRepository>().watchAllSurat(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
        final items = snapshot.data ?? [];
        
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status == 'pending' ? 'ANTRIAN PENGAJUAN' : 'ARSIP SURAT KELUAR', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text(
                      status == 'pending' 
                        ? 'Klik tombol proses untuk memberikan nomor surat resmi pada pengajuan warga.' 
                        : 'Daftar surat pengantar yang telah disetujui dan diberikan nomor resmi.', 
                      style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5)
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(status == 'pending' ? Icons.mail_outline_rounded : Icons.mark_as_unread_rounded, size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Text('Tidak ada data ${status == 'pending' ? 'antrian' : 'arsip'}.', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (c, i) {
                      final s = items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(28), 
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(s.namaLengkap, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)))),
                                if (status == 'approved') Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(s.nomorSurat ?? '-', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('KEPERLUAN: ${s.keperluan}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            const Divider(height: 40),
                            if (status == 'pending')
                              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => _showProcessModal(context, s), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('PROSES & BERI NOMOR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5))))
                            else
                              Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20), const SizedBox(width: 8), const Text('Sudah Terbit & Terarsipkan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))]),
                          ],
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}
