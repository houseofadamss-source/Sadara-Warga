import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminManageSuratScreen extends StatefulWidget {
  const AdminManageSuratScreen({super.key});

  @override
  State<AdminManageSuratScreen> createState() => _AdminManageSuratScreenState();
}

class _AdminManageSuratScreenState extends State<AdminManageSuratScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _updateStatus(String id, String status, {String? noSurat}) async {
    try {
      final data = {'status': status};
      if (noSurat != null) data['nomor_surat'] = noSurat;

      await Supabase.instance.client.from('surat_pengantar').update(data).eq('id', id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status surat diperbarui!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _showProcessModal(Map<String, dynamic> surat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proses Surat Pengantar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Pemohon: ${surat['nama_lengkap']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('Input Nomor Surat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _noSuratCtrl,
              decoration: InputDecoration(hintText: 'Contoh: 001/SP/RT03/VI/2026', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _updateStatus(surat['id'], 'approved', noSurat: _noSuratCtrl.text.trim());
                  _noSuratCtrl.clear();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('SETUJUI & TERBITKAN', style: TextStyle(fontWeight: FontWeight.bold)),
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
          labelColor: primaryTeal, unselectedLabelColor: Colors.grey, indicatorColor: primaryTeal,
          tabs: const [Tab(text: 'PENDING'), Tab(text: 'SELESAI')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildList('pending'), _buildList('approved')],
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('surat_pengantar').stream(primaryKey: ['id']).eq('status', status).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status == 'pending' ? 'ANTRIAN SURAT' : 'ARSIP SURAT KELUAR', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text(
                      status == 'pending' 
                        ? 'Periksa data warga di bawah ini. Pastikan data sudah sesuai sebelum memberikan nomor surat resmi.' 
                        : 'Berikut adalah daftar surat yang sudah Anda setujui dan siap diberikan tanda tangan basah.', 
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
                      Icon(status == 'pending' ? Icons.mail_outline_rounded : Icons.mark_as_unread_rounded, size: 64, color: Colors.grey.shade300),
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
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(24), 
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s['nama_lengkap'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                if (status == 'approved') Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(s['nomor_surat'] ?? '-', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Keperluan: ${s['keperluan']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const Divider(height: 32),
                            if (status == 'pending')
                              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showProcessModal(s), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('PROSES & BERI NOMOR')))
                            else
                              Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 8), const Text('Siap Tanda Tangan Basah', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))]),
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
