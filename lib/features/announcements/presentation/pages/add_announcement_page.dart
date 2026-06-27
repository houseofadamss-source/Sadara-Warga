import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/announcement_entity.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';

class AddAnnouncementPage extends StatelessWidget {
  final AnnouncementEntity? announcement;
  const AddAnnouncementPage({super.key, this.announcement});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnnouncementBloc>(),
      child: AddAnnouncementView(announcement: announcement),
    );
  }
}

class AddAnnouncementView extends StatefulWidget {
  final AnnouncementEntity? announcement;
  const AddAnnouncementView({super.key, this.announcement});

  @override
  State<AddAnnouncementView> createState() => _AddAnnouncementViewState();
}

class _AddAnnouncementViewState extends State<AddAnnouncementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _picker = ImagePicker();
  
  final _kabarJudulCtrl = TextEditingController();
  final _kabarIsiCtrl = TextEditingController();
  int _charCount = 0;
  File? _selectedImage;
  String? _existingImageUrl;
  
  final _beritaLinkCtrl = TextEditingController();
  String? _autoTitle;
  String? _autoDesc;
  String? _autoImage;

  bool _isFetchingMetadata = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.announcement != null) {
      final a = widget.announcement!;
      if (a.tipe == 'kabar') {
        _kabarJudulCtrl.text = a.judul;
        _kabarIsiCtrl.text = a.konten;
        _charCount = a.konten.length;
        _existingImageUrl = a.fileUrl;
        _tabController.index = 0;
      } else {
        _beritaLinkCtrl.text = a.konten;
        _autoTitle = a.judul;
        _autoDesc = a.subJudul;
        _autoImage = a.fileUrl;
        _tabController.index = 1;
      }
    }

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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Ambil Foto Langsung'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _insertMarkdown(String startTag, [String endTag = '']) {
    final text = _kabarIsiCtrl.text;
    final selection = _kabarIsiCtrl.selection;
    
    String newText;
    int newOffset;

    if (selection.isValid && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      newText = text.replaceRange(selection.start, selection.end, '$startTag$selectedText$endTag');
      newOffset = selection.end + startTag.length + endTag.length;
    } else {
      final currentPos = selection.baseOffset;
      final actualPos = currentPos < 0 ? text.length : currentPos;
      newText = text.replaceRange(actualPos, actualPos, '$startTag$endTag');
      newOffset = actualPos + startTag.length;
    }

    _kabarIsiCtrl.text = newText;
    _kabarIsiCtrl.selection = TextSelection.collapsed(offset: newOffset);
  }

  Future<void> _fetchMetadata(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    setState(() => _isFetchingMetadata = true);
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
      if (mounted) setState(() => _isFetchingMetadata = false);
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

  void _onPublishPressed(BuildContext context, String tipe) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    String judul = '';
    String konten = '';
    String? subJudul;
    String? fileUrl = widget.announcement?.fileUrl;

    if (tipe == 'kabar') {
      if (_kabarJudulCtrl.text.isEmpty || _kabarIsiCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan isi wajib diisi')));
        return;
      }
      
      judul = _kabarJudulCtrl.text.trim();
      konten = _kabarIsiCtrl.text.trim();
      
      if (_selectedImage != null) {
        fileUrl = await _uploadImage(_selectedImage!);
      }
    } else {
      if (_autoTitle == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link tidak valid atau ringkasan tidak ditemukan.')));
        return;
      }
      judul = _autoTitle!;
      subJudul = _autoDesc;
      konten = _beritaLinkCtrl.text.trim();
      fileUrl = _autoImage;
    }

    final announcement = AnnouncementEntity(
      id: widget.announcement?.id ?? const Uuid().v4(),
      judul: judul,
      konten: konten,
      subJudul: subJudul,
      fileUrl: fileUrl,
      tipe: tipe,
      isFeatured: widget.announcement?.isFeatured ?? false,
      createdAt: widget.announcement?.createdAt ?? DateTime.now(),
      authorId: widget.announcement?.authorId ?? user.id,
    );

    if (context.mounted) {
      if (widget.announcement == null) {
        context.read<AnnouncementBloc>().add(AddAnnouncementRequested(announcement));
      } else {
        context.read<AnnouncementBloc>().add(UpdateAnnouncementRequested(announcement));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    
    return BlocListener<AnnouncementBloc, AnnouncementState>(
      listener: (context, state) {
        if (state is AnnouncementActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          Navigator.pop(context);
        } else if (state is AnnouncementFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
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
          children: [_buildKabarForm(context, primaryTeal), _buildBeritaForm(context, primaryTeal)],
        ),
      ),
    );
  }

  Widget _buildKabarForm(BuildContext context, Color primary) {
    final state = context.watch<AnnouncementBloc>().state;
    final bool isLoading = state is AnnouncementLoading;

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
                
                // Markdown Toolbar
                Row(
                  children: [
                    _toolbarIcon(Icons.format_bold_rounded, () => _insertMarkdown('**', '**')),
                    _toolbarIcon(Icons.format_italic_rounded, () => _insertMarkdown('_', '_')),
                    _toolbarIcon(Icons.format_underlined_rounded, () => _insertMarkdown('<u>', '</u>')),
                    _toolbarIcon(Icons.format_list_bulleted_rounded, () => _insertMarkdown('\n- ')),
                    _toolbarIcon(Icons.link_rounded, () => _insertMarkdown('[Judul Link](', ')')),
                    const Spacer(),
                    Text(
                      '$_charCount / 1000',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _charCount >= 950 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                TextField(
                  controller: _kabarIsiCtrl, 
                  maxLines: 10, 
                  maxLength: 1000, 
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: const InputDecoration(hintText: 'Tulis pesan lengkap di sini...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.black12))
                ),
                
                if (_selectedImage != null || _existingImageUrl != null) 
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: double.infinity, height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: _selectedImage != null 
                              ? FileImage(_selectedImage!) as ImageProvider
                              : NetworkImage(_existingImageUrl!), 
                            fit: BoxFit.cover
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10, top: 30,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImage = null;
                            _existingImageUrl = null;
                          }),
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
                    onPressed: _showImagePickerOptions,
                    avatar: Icon(Icons.add_a_photo_rounded, color: primary, size: 16),
                    label: Text(_selectedImage == null ? 'Lampirkan Foto' : 'Ganti Foto', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    backgroundColor: primary.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _onPublishPressed(context, 'kabar'),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: isLoading 
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

  Widget _toolbarIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildBeritaForm(BuildContext context, Color primary) {
    final state = context.watch<AnnouncementBloc>().state;
    final bool isLoading = state is AnnouncementLoading;

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
          
          if (_isFetchingMetadata) 
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
              onPressed: (_autoTitle != null && !isLoading) ? () => _onPublishPressed(context, 'berita') : null,
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
              child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('BAGIKAN BERITA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
