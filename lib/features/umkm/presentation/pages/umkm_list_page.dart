import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/umkm_entity.dart';
import '../bloc/umkm_bloc.dart';
import '../bloc/umkm_event.dart';
import '../bloc/umkm_state.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class UmkmListPage extends StatelessWidget {
  final String userNik;
  const UmkmListPage({super.key, required this.userNik});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UmkmBloc>()..add(FetchApprovedUmkm()),
      child: const UmkmListView(),
    );
  }
}

class UmkmListView extends StatelessWidget {
  const UmkmListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('DIREKTORI UMKM',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: BlocConsumer<UmkmBloc, UmkmState>(
        listener: (context, state) {
          if (state is UmkmActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is UmkmFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is UmkmLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          List<UmkmEntity> items = [];
          if (state is UmkmLoaded) {
            items = state.umkmList;
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<UmkmBloc>().add(FetchApprovedUmkm());
            },
            child: CustomScrollView(
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
                            Text('USAHA WARGA SINAGAR',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    color: Colors.amber.shade900)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Daftar resmi pelaku usaha di wilayah Kp. Sinagar yang telah terverifikasi.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
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
                        (c, i) => _buildWargaCard(context, items[i]),
                        childCount: items.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterModal(context),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('DAFTARKAN USAHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWargaCard(BuildContext context, UmkmEntity umkm) {
    String displayCategory = umkm.jenisDagangan.split('(')[0].trim().toUpperCase();

    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWargaDetail(context, umkm),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                  child: umkm.fotoUrl != null
                      ? Image.network(umkm.fotoUrl!, fit: BoxFit.cover)
                      : Container(
                          color: primaryTeal.withOpacity(0.1),
                          child: const Icon(Icons.store, color: primaryTeal)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(umkm.namaBisnis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(displayCategory,
                          style: const TextStyle(
                              color: primaryTeal, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(umkm.produkUtama,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                String phone = umkm.nomorWa.replaceAll(RegExp(r'[^0-9]'), '');
                                if (phone.startsWith('0')) {
                                  phone = '62${phone.substring(1)}';
                                } else if (phone.startsWith('8')) {
                                  phone = '62$phone';
                                }
                                final url = Uri.parse("https://wa.me/$phone");
                                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text('HUBUNGI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                                color: primaryTeal.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.info_outline_rounded, size: 16, color: primaryTeal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWargaDetail(BuildContext context, UmkmEntity umkm) {
    String displayCategory = umkm.jenisDagangan.split('(')[0].trim().toUpperCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
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
                        if (umkm.fotoUrl != null)
                          ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              child: Image.network(umkm.fotoUrl!, height: 280, width: double.infinity, fit: BoxFit.cover))
                        else
                          Container(
                              height: 200,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                  color: primaryTeal, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                              child: const Icon(Icons.store_rounded, color: Colors.white, size: 60)),
                        Positioned(
                            top: 20,
                            right: 20,
                            child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.3),
                                child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => Navigator.pop(c)))),
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
                                  decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(displayCategory,
                                      style: const TextStyle(
                                          color: primaryTeal,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5))),
                              const Row(children: [
                                Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text('Verified',
                                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12))
                              ]),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(umkm.namaBisnis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 8),
                          Text(umkm.produkUtama,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          const Text('JAM OPERASIONAL',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoBadge(Icons.access_time_rounded, '${umkm.jamBuka} - ${umkm.jamTutup}', Colors.blue),
                              const SizedBox(width: 12),
                              _buildInfoBadge(Icons.calendar_today_rounded, umkm.hariLibur, Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text('TENTANG USAHA',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          MarkdownBody(
                            data: umkm.deskripsi,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
                              listBullet: const TextStyle(fontSize: 14, color: primaryTeal),
                              strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  void _showRegisterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => BlocProvider.value(
        value: context.read<UmkmBloc>(),
        child: const _UmkmModalContent(),
      ),
    );
  }
}

class _UmkmModalContent extends StatefulWidget {
  const _UmkmModalContent();

  @override
  State<_UmkmModalContent> createState() => _UmkmModalContentState();
}

class _UmkmModalContentState extends State<_UmkmModalContent> {
  final _nameCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _openTimeCtrl = TextEditingController(text: '08:00');
  final _closeTimeCtrl = TextEditingController(text: '21:00');
  final _holidayCtrl = TextEditingController(text: 'Buka Setiap Hari');

  String? _selectedCategory;
  File? _imageFile;
  LatLng _selectedLoc = const LatLng(-6.579545, 106.7162769);

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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AMBIL FOTO USAHA',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildSourceCard(Icons.camera_alt_rounded, 'Kamera', ImageSource.camera)),
                const SizedBox(width: 16),
                Expanded(child: _buildSourceCard(Icons.photo_library_rounded, 'Galeri', ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        final picker = ImagePicker();
        final img = await picker.pickImage(source: source, imageQuality: 50);
        if (img != null) setState(() => _imageFile = File(img.path));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(children: [
          Icon(icon, color: primaryTeal, size: 32),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
        ]),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_imageFile == null || _nameCtrl.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi data dan foto usaha!')));
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final fileName = 'umkm_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from('umkm_foto').upload(fileName, _imageFile!);
    final imgUrl = client.storage.from('umkm_foto').getPublicUrl(fileName);

    final umkm = UmkmEntity(
      id: const Uuid().v4(),
      userId: user.id,
      namaBisnis: _nameCtrl.text.trim(),
      jenisDagangan: _selectedCategory!,
      produkUtama: _prodCtrl.text.trim(),
      nomorWa: _waCtrl.text.trim(),
      deskripsi: _descCtrl.text.trim(),
      jamBuka: _openTimeCtrl.text.trim(),
      jamTutup: _closeTimeCtrl.text.trim(),
      hariLibur: _holidayCtrl.text.trim(),
      fotoUrl: imgUrl,
      latitude: _selectedLoc.latitude,
      longitude: _selectedLoc.longitude,
      status: 'pending',
      isWeeklyFeatured: false,
      isPushedToOsm: false,
    );

    if (context.mounted) {
      context.read<UmkmBloc>().add(RegisterUmkmRequested(umkm));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UmkmBloc, UmkmState>(
      builder: (context, state) {
        final bool isSubmitting = state is UmkmLoading;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration:
              const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
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
                      const Text('Gunakan **Teks Bold** atau - Poin untuk deskripsi yang menarik.',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: isSubmitting ? null : _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200)),
                          child: _imageFile != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
                              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_a_photo_rounded, color: primaryTeal, size: 32),
                                  SizedBox(height: 8),
                                  Text('Ambil Foto Usaha',
                                      style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12))
                                ]),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLabel('INFORMASI BISNIS'),
                      _buildField('Nama Bisnis / Toko', _nameCtrl),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildField('Produk Utama (Contoh: Nasi Goreng)', _prodCtrl),
                      const SizedBox(height: 16),
                      _buildField('Nomor WhatsApp', _waCtrl, keyboardType: TextInputType.phone),
                      const SizedBox(height: 32),
                      _buildLabel('JAM OPERASIONAL'),
                      Row(
                        children: [
                          Expanded(child: _buildField('Jam Buka (Misal: 08:00)', _openTimeCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField('Jam Tutup (Misal: 21:00)', _closeTimeCtrl)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField('Hari Libur (Contoh: Minggu Tutup)', _holidayCtrl),
                      const SizedBox(height: 32),
                      _buildLabel('DESKRIPSI LENGKAP (MARKDOWN OK)'),
                      _buildField('Ceritakan usaha Anda. Gunakan **bold** atau poin-poin agar rapi...', _descCtrl, maxLines: 6),
                      const SizedBox(height: 32),
                      _buildLabel('TITIK LOKASI (MAPS)'),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FlutterMap(
                            options: MapOptions(
                                initialCenter: _selectedLoc, initialZoom: 16, onTap: (p, l) => setState(() => _selectedLoc = l)),
                            children: [
                              TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.sadarawarga.app'),
                              MarkerLayer(markers: [
                                Marker(
                                    point: _selectedLoc,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40))
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () => _submit(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0),
                          child: isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('TERBITKAN USAHA SEKARANG',
                                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 1)));

  Widget _buildField(String hint, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black12, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Pilih Kategori Usaha', style: TextStyle(fontSize: 14, color: Colors.black26)),
          isExpanded: true,
          items: _categories
              .map((c) =>
                  DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }
}
