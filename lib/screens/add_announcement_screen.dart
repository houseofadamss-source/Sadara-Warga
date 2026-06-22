import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:image_picker/image_picker.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _picker = ImagePicker();
  
  // Kabar Instant State
  final _kabarJudulCtrl = TextEditingController();
  final _kabarIsiCtrl = TextEditingController();
  int _charCount = 0;
  File? _selectedImage;
  
  // Berita Link State
  final _beritaLinkCtrl = TextEditingController();
  String? _autoTitle;
  String? _autoDesc;
  String? _autoImage;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kabarIsiCtrl.addListener(() {
      setState(() {
        _charCount = _kabarIsiCtrl.text.length;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kabarJudulCtrl.dispose();
    _kabarIsiCtrl.dispose();
    _beritaLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _fetchMetadata(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    setState(() => _isLoading = true);
    try {
      var data = await MetadataFetch.extract(url);
      setState(() {
        _autoTitle = data?.title;
        _autoDesc = data?.description;
        _autoImage = data?.image;
      });
    } catch (e) {
      debugPrint('Metadata error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'kabar/$fileName';
      
      await Supabase.instance.client.storage
          .from('announcements')
          .upload(path, file);

      final imageUrl = Supabase.instance.client.storage
          .from('announcements')
          .getPublicUrl(path);
          
      return imageUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _publish(String tipe) async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw 'Sesi berakhir, silakan login ulang.';

      Map<String, dynamic> payload = {
        'tipe': tipe,
        'author_id': user.id,
      };

      if (tipe == 'kabar') {
        if (_kabarJudulCtrl.text.isEmpty || _kabarIsiCtrl.text.isEmpty) throw 'Judul dan isi wajib diisi';
        
        String? uploadedUrl;
        if (_selectedImage != null) {
          uploadedUrl = await _uploadImage(_selectedImage!);
        }

        payload.addAll({
          'judul': _kabarJudulCtrl.text.trim(),
          'konten': _kabarIsiCtrl.text.trim(),
          'file_url': uploadedUrl,
        });
      } else {
        if (_autoTitle == null) throw 'Link tidak valid atau ringkasan tidak ditemukan.';
        payload.addAll({
          'judul': _autoTitle,
          'sub_judul': _autoDesc,
          'konten': _beritaLinkCtrl.text.trim(), // Link URL simpan di kolom konten
          'file_url': _autoImage,
        });
      }

      await client.from('announcements').insert(payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tipe == 'kabar' ? 'Kabar' : 'Berita'} berhasil diterbitkan!'), backgroundColor: const Color(0xFF0F766E))
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menerbitkan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: true,
        title: const Text('BUAT PENGUMUMAN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal, unselectedLabelColor: Colors.grey,
          indicatorColor: primaryTeal, indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'KABAR INSTANT'), 
            Tab(text: 'BERITA ONLINE')
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildKabarForm(primaryTeal), _buildBeritaForm(primaryTeal)],
      ),
    );
  }

  Widget _buildKabarForm(Color primary) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INFO CEPAT WARGA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                const Text(
                  'Tulis pesan singkat untuk segera diketahui oleh seluruh warga di aplikasi.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 32),
                const Text('JUDUL INFO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                TextField(
                  controller: _kabarJudulCtrl, 
                  decoration: const InputDecoration(hintText: 'Misal: Kerja Bakti Besok', border: InputBorder.none, hintStyle: TextStyle(color: Colors.black12)), 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const Divider(),
                const SizedBox(height: 12),
                const Text('PESAN (Maks 1000 Karakter)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                TextField(
                  controller: _kabarIsiCtrl, 
                  maxLines: 10, 
                  maxLength: 1000, 
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: const InputDecoration(hintText: 'Tulis pesan lengkap di sini...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.black12))
                ),
                
                if (_selectedImage != null) 
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: double.infinity, height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 10, top: 30,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: CircleAvatar(radius: 15, backgroundColor: Colors.black.withValues(alpha: 0.5), child: const Icon(Icons.close, size: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ActionChip(
                    onPressed: _pickImage,
                    avatar: Icon(Icons.add_a_photo_rounded, color: primary, size: 16),
                    label: Text(_selectedImage == null ? 'Lampirkan Foto' : 'Ganti Foto', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    backgroundColor: primary.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  const Spacer(),
                  Text(
                    '$_charCount / 1000',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _charCount >= 950 ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _publish('kabar'),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('TERBITKAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBeritaForm(Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BAGIKAN BERITA ONLINE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text(
            'Tempelkan link berita dari portal berita terpercaya, sistem akan otomatis mengambil ringkasan beritanya untuk warga.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text('LINK BERITA / ARTIKEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _beritaLinkCtrl, 
            onChanged: _fetchMetadata,
            decoration: InputDecoration(
              hintText: 'https://...', filled: true, fillColor: const Color(0xFFF8FAFC),
              hintStyle: const TextStyle(color: Colors.black12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary)),
              prefixIcon: Icon(Icons.link_rounded, color: primary),
            ),
          ),
          const SizedBox(height: 32),
          
          if (_isLoading) 
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_autoTitle != null) 
            _buildPreviewCard()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome_motion_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    const Text('Pratinjau berita akan muncul di sini setelah link ditempel.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 58,
            child: ElevatedButton(
              onPressed: (_autoTitle != null && !_isLoading) ? () => _publish('berita') : null,
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
              child: const Text('BAGIKAN BERITA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_autoImage != null) 
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(_autoImage!, height: 180, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PREVIEW BERITA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(_autoTitle ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(_autoDesc ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
