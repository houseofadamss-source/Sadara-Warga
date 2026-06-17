import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/osm_api_service.dart'; // Import Baru

class AdminUmkmManagementScreen extends StatefulWidget {
  const AdminUmkmManagementScreen({super.key});

  @override
  State<AdminUmkmManagementScreen> createState() => _AdminUmkmManagementScreenState();
}

class _AdminUmkmManagementScreenState extends State<AdminUmkmManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OsmApiService _osmApi = OsmApiService(); // Instance baru
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

  Future<void> _updateStatus(String id, String status) async {
    try {
      await Supabase.instance.client.from('umkm').update({'status': status}).eq('id', id);
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? 'UMKM berhasil disetujui!' : 'UMKM ditolak.'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _toggleFeatured(String id, bool currentVal) async {
    try {
      if (!currentVal) {
        final countRes = await Supabase.instance.client.from('umkm').select().eq('is_weekly_featured', true);
        if ((countRes as List).length >= 3) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 3 UMKM yang bisa mejeng di Beranda!'), backgroundColor: Colors.orange));
          return;
        }
      }

      await Supabase.instance.client.from('umkm').update({'is_weekly_featured': !currentVal}).eq('id', id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('MANAJEMEN UMKM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'VERIFIED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUmkmList('pending'),
          _buildUmkmList('approved'),
        ],
      ),
    );
  }

  Widget _buildUmkmList(String statusFilter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('umkm').stream(primaryKey: ['id']).eq('status', statusFilter).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final list = snapshot.data ?? [];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusFilter == 'pending' ? 'VERIFIKASI USAHA' : 'DAFTAR UMKM WARGA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusFilter == 'pending'
                          ? 'Periksa detail usaha dan lokasi warga sebelum memberikan persetujuan untuk ditampilkan di publik.'
                          : 'Kelola promosi mingguan UMKM yang sudah terverifikasi agar muncul di halaman depan aplikasi warga.',
                      style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            if (list.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(statusFilter == 'pending' ? 'Tidak ada permintaan baru.' : 'Belum ada UMKM terverifikasi.', style: const TextStyle(color: Colors.grey))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = list[index];
                      final isFeatured = item['is_weekly_featured'] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(item['foto_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey.shade100, child: const Icon(Icons.store, color: Colors.grey))),
                              ),
                              title: Text(item['nama_bisnis'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                              subtitle: Text(item['jenis_dagangan'] ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              trailing: statusFilter == 'approved' 
                                ? Switch(
                                    value: isFeatured,
                                    activeColor: primaryTeal,
                                    onChanged: (v) => _toggleFeatured(item['id'], isFeatured),
                                  )
                                : null,
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(item['deskripsi'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),

                            if (item['latitude'] != null && item['longitude'] != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: InkWell(
                                  onTap: () async {
                                    // BUKA DI OPENSTREETMAP (In-App WebView)
                                    final url = Uri.parse("https://www.openstreetmap.org/?mlat=${item['latitude']}&mlon=${item['longitude']}#map=18/${item['latitude']}/${item['longitude']}");
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 14, color: Colors.blue),
                                        SizedBox(width: 6),
                                        Text('Lihat Lokasi Usaha', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: statusFilter == 'pending'
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateStatus(item['id'], 'approved'),
                                          style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          child: const Text('SETUJUI', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _updateStatus(item['id'], 'rejected'),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          child: const Text('TOLAK'),
                                        ),
                                      ),
                                    ],
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        if (isFeatured)
                                          const Row(children: [Icon(Icons.auto_awesome, color: Colors.amber, size: 14), SizedBox(width: 4), Text('Mejeng di Beranda', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11))]),
                                        const SizedBox(width: 8),
                                        // TOMBOL PUSH KE OSM
                                        IconButton(
                                          onPressed: () async {
                                            bool ok = await _osmApi.pushToOsm(item);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: Text(ok ? 'Berhasil diterbitkan ke Peta Dunia!' : 'Gagal terbit. Pastikan sudah login OSM.'),
                                                backgroundColor: ok ? Colors.blue : Colors.red,
                                              ));
                                            }
                                          }, 
                                          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                                          tooltip: 'Terbitkan ke Peta Dunia (OSM)',
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(onPressed: () => _updateStatus(item['id'], 'pending'), child: const Text('BATALKAN VERIFIKASI', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: list.length,
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
