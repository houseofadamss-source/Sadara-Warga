import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class AddReportScreen extends StatefulWidget {
  final String nik;
  final String nama;
  const AddReportScreen({super.key, required this.nik, required this.nama});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _selectedKategori = 'Umum';
  File? _imageFile;
  Position? _currentPosition;
  bool _isUploading = false;
  final _picker = ImagePicker();

  final List<String> _kategoriList = ['Umum', 'Keamanan', 'Kebersihan', 'Infrastruktur', 'Sosial'];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint('Error location: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitReport() async {
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Deskripsi harus diisi!')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final client = Supabase.instance.client;
      String? uploadedImageUrl;

      // 1. Upload Foto jika ada
      if (_imageFile != null) {
        final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'reports/$fileName';
        await client.storage.from('berkas_warga').upload(path, _imageFile!);
        uploadedImageUrl = client.storage.from('berkas_warga').getPublicUrl(path);
      }

      // 2. Simpan ke Database
      await client.from('reports').insert({
        'nik_warga': widget.nik,
        'nama_warga': widget.nama,
        'judul_laporan': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'kategori': _selectedKategori,
        'foto_url': uploadedImageUrl,
        'status': 'Menunggu',
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal kirim: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        title: const Text('Buat Laporan', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Foto Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                ),
                child: _imageFile != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_imageFile!, fit: BoxFit.cover))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 40, color: primaryTeal), SizedBox(height: 12), Text('Ambil Foto Kejadian', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold))]),
              ),
            ),
            const SizedBox(height: 24),
            
            // Pilih Kategori
            const Text('Kategori Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kategoriList.map((kat) {
                  bool isSelected = _selectedKategori == kat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedKategori = kat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryTeal : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(child: Text(kat, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Judul Kejadian'),
            _buildTextField('Contoh: Lampu Jalan Mati', _judulController),
            const SizedBox(height: 20),
            
            _buildLabel('Deskripsi Lengkap'),
            _buildTextField('Ceritakan detail kejadiannya...', _deskripsiController, maxLines: 5),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReport,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('KIRIM LAPORAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))));
  
  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller, maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        fillColor: const Color(0xFFF8FAFC), filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F766E))),
      ),
    );
  }
}
