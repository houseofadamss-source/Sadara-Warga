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
      Map<String, dynamic> data = {
        'tipe': tipe,
        'author_id': 'super_admin',
        'kategori': 'INFO',
        'created_at': DateTime.now().toIso8601String(), // JURUS SAKTI: Kirim jam HP detik ini!
      };

      if (tipe == 'kabar') {
        if (_kabarJudulCtrl.text.isEmpty || _kabarIsiCtrl.text.isEmpty) throw 'Judul dan isi wajib diisi';
        
        String? uploadedUrl;
        if (_selectedImage != null) {
          uploadedUrl = await _uploadImage(_selectedImage!);
        }

        data.addAll({
          'judul': _kabarJudulCtrl.text.trim(),
          'konten': _kabarIsiCtrl.text.trim(),
          'file_url': uploadedUrl,
        });
      } else {
        if (_autoTitle == null) throw 'Link tidak valid';
        data.addAll({
          'judul': _autoTitle,
          'sub_judul': _autoDesc,
          'blog_url': _beritaLinkCtrl.text.trim(),
          'file_url': _autoImage,
          'konten': 'Baca selengkapnya di link tersebut.',
        });
      }

      await Supabase.instance.client.from('announcements').insert(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tipe == 'kabar' ? 'Kabar' : 'Berita'} berhasil dikirim!'), backgroundColor: const Color(0xFF0F766E))
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('TERBITKAN INFO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal, unselectedLabelColor: Colors.grey,
          indicatorColor: primaryTeal, indicatorWeight: 3,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Kabar Instant'),
                ],
              ),
            ), 
            Tab(text: 'Berita Link')
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BAGIKAN INFO TERBARU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    SizedBox(height: 8),
                    Text(
                      'Tulis pesan singkat atau kabar mendadak untuk segera diketahui oleh seluruh warga di aplikasi.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('JUDUL KABAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                TextField(controller: _kabarJudulCtrl, decoration: const InputDecoration(hintText: 'Info Singkat...', border: InputBorder.none), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('ISI PESAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                TextField(
                  controller: _kabarIsiCtrl, 
                  maxLines: 8, 
                  maxLength: 1000, 
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: const InputDecoration(hintText: 'Tulis pesan...', border: InputBorder.none)
                ),
                
                // PREVIEW FOTO (Hanya muncul kalau sudah pilih foto)
                if (_selectedImage != null) 
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 0, top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        // TOOLBAR BAWAH (Icon Foto nempel di kiri bawah)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: Icon(Icons.add_a_photo_rounded, color: primary),
                    tooltip: 'Tambah Foto',
                  ),
                  const Text('Lampirkan Foto', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    '$_charCount/1000',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _charCount >= 1000 ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _publish('kabar'),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('KIRIM SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TERBITKAN BERITA LENGKAP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 8),
              Text(
                'Tempelkan link berita dari blog luar (Notion/Substack), sistem akan otomatis mengambil ringkasan beritanya untuk warga.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('LINK BLOG (SUBSTACK/NOTION)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: _beritaLinkCtrl, onChanged: _fetchMetadata,
            decoration: InputDecoration(
              hintText: 'https://...', filled: true, fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.link, color: Colors.teal),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading) const Center(child: CircularProgressIndicator())
          else if (_autoTitle != null) _buildPreviewCard(),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: (_autoTitle != null && !_isLoading) ? () => _publish('berita') : null,
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('TERBITKAN BERITA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_autoImage != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_autoImage!, height: 120, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          Text(_autoTitle ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_autoDesc ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
