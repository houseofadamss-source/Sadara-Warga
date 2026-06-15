import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/osm_service.dart';

class UmkmListScreen extends StatefulWidget {
  final String userNik;
  const UmkmListScreen({super.key, required this.userNik});

  @override
  State<UmkmListScreen> createState() => _UmkmListScreenState();
}

class _UmkmListScreenState extends State<UmkmListScreen> {
  List<Map<String, dynamic>> _wargaUmkm = [];
  List<Map<String, dynamic>> _publicUmkm = [];
  bool _isLoading = true;
  bool _hasErrorOsm = false;

  @override
  void initState() {
    super.initState();
    _fetchHybridData();
  }

  Future<void> _fetchHybridData() async {
    setState(() { _isLoading = true; _hasErrorOsm = false; });
    try {
      final wargaData = await Supabase.instance.client
          .from('umkm')
          .select()
          .eq('status', 'approved')
          .order('is_weekly_featured', ascending: false);

      final osmService = OsmService();
      final publicData = await osmService.fetchNearbyUmkm();

      if (mounted) {
        setState(() {
          _wargaUmkm = List<Map<String, dynamic>>.from(wargaData);
          _publicUmkm = publicData;
          _isLoading = false;
          _hasErrorOsm = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasErrorOsm = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('DIREKTORI UMKM', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHybridData,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text('UMKM SINAGAR (VERIFIED)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.amber.shade900)),
                      ],
                    ),
                  ),
                ),
                if (_wargaUmkm.isEmpty)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Belum ada UMKM warga terverifikasi.', style: TextStyle(fontSize: 12, color: Colors.grey)))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => _buildWargaCard(_wargaUmkm[i]),
                        childCount: _wargaUmkm.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.map_rounded, color: primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        const Text('PILIHAN LAIN SEKITAR ANDA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: primaryTeal)),
                      ],
                    ),
                  ),
                ),
                if (_publicUmkm.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40), 
                      child: Center(
                        child: Text(
                          _hasErrorOsm ? 'Gagal mengambil data sekitar.' : 'Belum ada data toko publik di radius ini.', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)
                        )
                      )
                    )
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => _buildPublicCard(_publicUmkm[i]),
                        childCount: _publicUmkm.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterModal(context),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('DAFTARKAN USAHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWargaCard(Map<String, dynamic> umkm) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (umkm['foto_url'] != null)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(umkm['foto_url'], height: 160, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(umkm['nama_bisnis'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(umkm['jenis_dagangan'].toString().toUpperCase(), style: const TextStyle(color: primaryTeal, fontSize: 8, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(umkm['produk_utama'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Text(umkm['deskripsi'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final phone = umkm['nomor_wa'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                          final url = Uri.parse("https://wa.me/${phone.startsWith('0') ? '62${phone.substring(1)}' : phone}");
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                        label: const Text('PESAN SEKARANG'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      ),
                    ),
                    if (umkm['latitude'] != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${umkm['latitude']},${umkm['longitude']}");
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.location_on_rounded, color: Colors.blue),
                        style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), padding: const EdgeInsets.all(12)),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicCard(Map<String, dynamic> umkm) {
    const Color textDark = Color(0xFF1E293B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white)),
      child: Row(
        children: [
          Container(height: 50, width: 50, decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.storefront_rounded, color: Colors.teal, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(umkm['nama_bisnis'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(umkm['jenis_dagangan'].toString().replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${umkm['latitude']},${umkm['longitude']}");
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.near_me_rounded, color: Colors.blue, size: 20),
            style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  void _showRegisterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _UmkmModalContent(
          userNik: widget.userNik,
          onSuccess: () { Navigator.pop(context); _fetchHybridData(); },
        );
      },
    );
  }
}

class _UmkmModalContent extends StatefulWidget {
  final String userNik;
  final VoidCallback onSuccess;
  const _UmkmModalContent({required this.userNik, required this.onSuccess});

  @override
  State<_UmkmModalContent> createState() => _UmkmModalContentState();
}

class _UmkmModalContentState extends State<_UmkmModalContent> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Position? _currentPosition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) { debugPrint('Loc error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text('Daftar UMKM Warga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField('Nama Bisnis', 'Contoh: Warung Barokah', _nameCtrl),
            const SizedBox(height: 16),
            _buildField('Kategori', 'Contoh: Makanan/Jasa/Sembako', _typeCtrl),
            const SizedBox(height: 16),
            _buildField('Produk Utama', 'Contoh: Nasi Goreng, Ayam Bakar', _prodCtrl),
            const SizedBox(height: 16),
            _buildField('Nomor WhatsApp', '0812...', _waCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('Deskripsi', 'Ceritakan sedikit tentang usaha Anda...', _descCtrl, maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                   setState(() => _isSubmitting = true);
                   try {
                     await Supabase.instance.client.from('umkm').insert({
                       'user_id': widget.userNik,
                       'nama_bisnis': _nameCtrl.text.trim(),
                       'jenis_dagangan': _typeCtrl.text.trim(),
                       'produk_utama': _prodCtrl.text.trim(),
                       'nomor_wa': _waCtrl.text.trim(),
                       'deskripsi': _descCtrl.text.trim(),
                       'latitude': _currentPosition?.latitude,
                       'longitude': _currentPosition?.longitude,
                       'status': 'pending'
                     });
                     widget.onSuccess();
                   } catch (e) { setState(() => _isSubmitting = false); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('DAFTARKAN SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: keyboardType, maxLines: maxLines, decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)))),
    ]);
  }
}
