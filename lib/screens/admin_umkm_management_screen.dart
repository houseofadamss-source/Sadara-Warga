import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/osm_api_service.dart';

class AdminUmkmManagementScreen extends StatefulWidget {
  const AdminUmkmManagementScreen({super.key});

  @override
  State<AdminUmkmManagementScreen> createState() => _AdminUmkmManagementScreenState();
}

class _AdminUmkmManagementScreenState extends State<AdminUmkmManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OsmApiService _osmApi = OsmApiService();
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

  Future<void> _updateStatus(dynamic id, String status) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status,
      };
      
      if (status == 'approved') {
        updateData['is_weekly_featured'] = false;
      }

      await Supabase.instance.client.from('umkm').update(updateData).eq('id', id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? 'UMKM berhasil diverifikasi!' : 'UMKM ditolak.'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _toggleFeatured(dynamic id, bool currentVal) async {
    try {
      if (!currentVal) {
        final res = await Supabase.instance.client.from('umkm').select().eq('is_weekly_featured', true);
        if ((res as List).length >= 5) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 5 UMKM Unggulan di Beranda!'), backgroundColor: Colors.orange));
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
            Tab(text: 'PENGAJUAN'),
            Tab(text: 'TERVERIFIKASI'),
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
                      statusFilter == 'pending' ? 'ANTRIAN VERIFIKASI' : 'KATALOG USAHA WARGA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusFilter == 'pending'
                          ? 'Periksa kelengkapan data usaha warga. UMKM yang diverifikasi akan masuk ke daftar fitur UMKM.'
                          : 'Pilih UMKM terbaik untuk ditampilkan di halaman utama Beranda sebagai Unggulan Minggu Ini.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            if (list.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(statusFilter == 'pending' ? 'Tidak ada antrian pendaftaran.' : 'Belum ada usaha yang diverifikasi.', style: const TextStyle(color: Colors.grey, fontSize: 13))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = list[index];
                      final bool isFeatured = item['is_weekly_featured'] ?? false;
                      final bool isPushed = item['is_pushed_to_osm'] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(item['foto_url'] ?? '', width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.store, color: Colors.grey))),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['nama_bisnis'] ?? '-', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 16)),
                                      Text(item['jenis_dagangan'] ?? '-', style: TextStyle(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                if (statusFilter == 'approved')
                                  StatefulBuilder(
                                    builder: (context, setTileState) => Switch(
                                      value: item['is_weekly_featured'] ?? false,
                                      activeThumbColor: primaryTeal,
                                      activeTrackColor: primaryTeal.withValues(alpha: 0.2),
                                      onChanged: (v) async {
                                        setTileState(() {
                                          item['is_weekly_featured'] = v;
                                        });
                                        await _toggleFeatured(item['id'], !v);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            Text(item['deskripsi'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                            
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final url = Uri.parse("https://www.openstreetmap.org/?mlat=${item['latitude']}&mlon=${item['longitude']}#map=18/${item['latitude']}/${item['longitude']}");
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 14, color: Colors.blue),
                                        SizedBox(width: 6),
                                        Text('LIHAT TITIK MAPS', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (statusFilter == 'approved')
                                  ElevatedButton.icon(
                                    onPressed: isPushed ? null : () async {
                                      bool ok = await _osmApi.pushToOsm(item);
                                      if (ok) {
                                        await Supabase.instance.client.from('umkm').update({'is_pushed_to_osm': true}).eq('id', item['id']);
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(ok ? 'Berhasil terbit di Peta Dunia!' : 'Gagal terbit ke OSM.'),
                                          backgroundColor: ok ? Colors.blue : Colors.red,
                                        ));
                                      }
                                    }, 
                                    icon: Icon(isPushed ? Icons.check_circle : Icons.cloud_done_rounded, size: 14),
                                    label: Text(isPushed ? 'DITERBITKAN' : 'PUSH OSM', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPushed ? Colors.grey.shade100 : Colors.blue.shade600,
                                      foregroundColor: isPushed ? Colors.grey : Colors.white,
                                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                    ),
                                  ),
                              ],
                            ),

                            if (statusFilter == 'pending') ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateStatus(item['id'], 'approved'),
                                      style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      child: const Text('VERIFIKASI USAHA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _updateStatus(item['id'], 'rejected'),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      child: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                               const SizedBox(height: 12),
                               if (isFeatured)
                                  Row(children: [const Icon(Icons.auto_awesome, color: Colors.amber, size: 14), const SizedBox(width: 6), Text('Sedang tayang di Beranda', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11))]),
                               Align(
                                 alignment: Alignment.centerRight,
                                 child: TextButton(onPressed: () => _updateStatus(item['id'], 'pending'), child: const Text('BATALKAN VERIFIKASI', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                               ),
                            ],
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
