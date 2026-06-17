import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UmkmListScreen extends StatefulWidget {
  final String userNik;
  const UmkmListScreen({super.key, required this.userNik});

  @override
  State<UmkmListScreen> createState() => _UmkmListScreenState();
}

class _UmkmListScreenState extends State<UmkmListScreen> {
  List<Map<String, dynamic>> _wargaUmkm = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocalUmkm();
  }

  Future<void> _fetchLocalUmkm() async {
    setState(() => _isLoading = true);
    try {
      final wargaData = await Supabase.instance.client
          .from('umkm')
          .select()
          .eq('status', 'approved')
          .order('is_weekly_featured', ascending: false);

      if (mounted) {
        setState(() {
          _wargaUmkm = List<Map<String, dynamic>>.from(wargaData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        onRefresh: _fetchLocalUmkm,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text('USAHA WARGA SINAGAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.amber.shade900)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Daftar resmi pelaku usaha di wilayah RT 003 RW 006 yang telah terverifikasi.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                if (_wargaUmkm.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada UMKM yang terdaftar.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (umkm['foto_url'] != null)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), child: Image.network(umkm['foto_url'], height: 180, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(umkm['nama_bisnis'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark))),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
                  child: Text(
                    (umkm['jenis_dagangan'] ?? '-').toString().split('(')[0].trim().toUpperCase(), 
                    style: const TextStyle(color: primaryTeal, fontSize: 8, fontWeight: FontWeight.bold)
                  )
                ),
                const SizedBox(height: 12),
                Text(umkm['produk_utama'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(umkm['deskripsi'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 24),
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
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _showWargaDetail(umkm),
                      icon: const Icon(Icons.info_outline_rounded, color: primaryTeal),
                      style: IconButton.styleFrom(backgroundColor: primaryTeal.withValues(alpha: 0.1), padding: const EdgeInsets.all(12)),
                    ),
                    if (umkm['latitude'] != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          final url = Uri.parse("https://www.openstreetmap.org/?mlat=${umkm['latitude']}&mlon=${umkm['longitude']}#map=18/${umkm['latitude']}/${umkm['longitude']}");
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.inAppBrowserView);
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

  void _showWargaDetail(Map<String, dynamic> umkm) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        if (umkm['foto_url'] != null)
                          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), child: Image.network(umkm['foto_url'], height: 280, width: double.infinity, fit: BoxFit.cover))
                        else
                          Container(height: 200, width: double.infinity, decoration: const BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: const Icon(Icons.store_rounded, color: Colors.white, size: 60)),
                        Positioned(top: 20, right: 20, child: CircleAvatar(backgroundColor: Colors.black.withValues(alpha: 0.3), child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
                                child: Text((umkm['jenis_dagangan'] ?? '-').toString().split('(')[0].trim().toUpperCase(), style: const TextStyle(color: primaryTeal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))
                              ),
                              const Row(children: [Icon(Icons.stars_rounded, color: Colors.amber, size: 16), SizedBox(width: 4), Text('Verified', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12))]),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(umkm['nama_bisnis'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 8),
                          Text(umkm['produk_utama'], style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          const Text('TENTANG USAHA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          MarkdownBody(
                            data: umkm['deskripsi'] ?? 'Tidak ada deskripsi tambahan.',
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
                              listBullet: const TextStyle(fontSize: 14, color: primaryTeal),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        String phone = umkm['nomor_wa'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                        if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
                        else if (phone.startsWith('8')) phone = '62$phone';
                        final url = Uri.parse("https://wa.me/$phone?text=Halo, saya tetangga dari Sadara Warga, mau tanya soal ${umkm['nama_bisnis']}");
                        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('PESAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  if (umkm['latitude'] != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () async {
                        final url = Uri.parse("https://www.openstreetmap.org/?mlat=${umkm['latitude']}&mlon=${umkm['longitude']}#map=18/${umkm['latitude']}/${umkm['longitude']}");
                        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                      },
                      icon: const Icon(Icons.location_on_rounded, color: Colors.blue),
                      style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UmkmModalContent(userNik: widget.userNik, onSuccess: _fetchLocalUmkm),
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
  final _prodCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  String? _selectedCategory;
  File? _imageFile;
  LatLng _selectedLoc = const LatLng(-6.579545, 106.7162769); // Default Sinagar
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Kuliner (Makanan & Minuman)',
    'Sembako & Toko Kelontong',
    'Jasa (Laundry, Jahit, dll)',
    'Produk Segar (Sayur, Daging)',
    'Fashion & Pakaian',
    'Elektronik & Handphone',
    'Otomotif & Bengkel',
    'Kesehatan & Apotek',
    'Kerajinan (Hand-made)',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _determineInitialLocation();
  }

  Future<void> _determineInitialLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _selectedLoc = LatLng(pos.latitude, pos.longitude));
    } catch (e) { /* ignore */ }
  }

  Future<void> _pickImage() async {
    const Color primaryTeal = Color(0xFF0F766E);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text('Sumber Foto Usaha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildModernPickerItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: primaryTeal,
                  onTap: () async {
                    Navigator.pop(c);
                    final picker = ImagePicker();
                    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                    if (img != null) setState(() => _imageFile = File(img.path));
                  },
                ),
                const SizedBox(width: 16),
                _buildModernPickerItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri HP',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(c);
                    final picker = ImagePicker();
                    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                    if (img != null) setState(() => _imageFile = File(img.path));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPickerItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // 1. Validasi Input Terlebih Dahulu
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajib upload foto tampak depan toko!'), backgroundColor: Colors.orange));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty || _selectedCategory == null || _waCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama Bisnis, Kategori, dan No WA wajib diisi!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Tampilkan info proses agar user tidak bingung jika upload lama
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sedang mendaftarkan usaha, mohon tunggu...'), duration: Duration(seconds: 2))
    );

    try {
      final client = Supabase.instance.client;
      
      // 2. Ambil UUID User berdasarkan NIK
      final userRes = await client.from('users').select('id').eq('nik', widget.userNik).maybeSingle();
      if (userRes == null) throw 'Identitas warga tidak ditemukan. Coba logout dan login kembali.';
      final String userId = userRes['id'];

      // 3. Upload Foto ke Storage
      final fileName = 'umkm_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from('umkm_foto').upload(fileName, _imageFile!, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
      final String imgUrl = client.storage.from('umkm_foto').getPublicUrl(fileName);

      // 4. Masukkan ke Database UMKM
      final response = await client.from('umkm').insert({
        'user_id': userId,
        'nama_bisnis': _nameCtrl.text.trim(),
        'jenis_dagangan': _selectedCategory,
        'produk_utama': _prodCtrl.text.trim(),
        'nomor_wa': _waCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'foto_url': imgUrl,
        'latitude': _selectedLoc.latitude,
        'longitude': _selectedLoc.longitude,
        'status': 'pending',
      }).select();

      if (response.isEmpty) throw 'Gagal menyimpan data ke database. Coba lagi nanti.';

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context); // Tutup modal
        widget.onSuccess(); // Trigger refresh di list utama
        messenger.showSnackBar(
          const SnackBar(
            content: Text('BERHASIL! UMKM Anda telah terdaftar dan menunggu persetujuan Pak RT.'), 
            backgroundColor: Color(0xFF0F766E),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        // Tampilkan dialog error yang lebih "galak" agar user sadar ada masalah
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Pendaftaran Gagal'),
            content: Text('Terjadi kendala: $e\n\nPastikan koneksi internet stabil dan semua data sudah benar.'),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daftarkan Usaha Anda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Demi akurasi navigasi bagi pelanggan, kami menyarankan Anda melakukan pendaftaran ini tepat di lokasi tempat usaha berada.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  // FOTO TAMPAK DEPAN
                  const Text('FOTO TAMPAK DEPAN TOKO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity, height: 160,
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                      child: _imageFile != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, color: primaryTeal, size: 32), SizedBox(height: 8), Text('Ambil Foto Usaha', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12))]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Nama Bisnis / Toko'),
                  _buildField('Contoh: Warung Barokah Berkah', _nameCtrl),
                  const SizedBox(height: 20),

                  _buildLabel('Kategori Usaha'),
                  _buildDropdown(),
                  const SizedBox(height: 20),

                  _buildLabel('Produk Utama'),
                  _buildField('Contoh: Nasi Goreng, Pulsa, atau Laundry', _prodCtrl),
                  const SizedBox(height: 20),

                  _buildLabel('Nomor WhatsApp (Aktif)'),
                  _buildField('Contoh: 08123456789', _waCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),

                  _buildLabel('Deskripsi Singkat Usaha'),
                  _buildField('Ceritakan apa yang unik dari usaha Anda...', _descCtrl, maxLines: 5),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Tips: Gunakan tanda (-) untuk daftar/list, dan bintang (**) untuk menebalkan teks.',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('TENTUKAN TITIK LOKASI (MAPS)'),
                  const SizedBox(height: 12),
                  Container(
                    height: 200, width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _selectedLoc,
                          initialZoom: 16,
                          onTap: (tapPos, latLng) => setState(() => _selectedLoc = latLng),
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.sadarawarga.app'),
                          MarkerLayer(
                            markers: [
                              Marker(point: _selectedLoc, width: 40, height: 40, child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('*Klik/Tap pada peta untuk memindahkan Pin ke lokasi yang tepat.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                      child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('AJUKAN SURAT SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));

  Widget _buildField(String hint, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200))),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Pilih Kategori', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }
}
