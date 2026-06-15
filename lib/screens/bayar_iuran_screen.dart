import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class BayarIuranScreen extends StatefulWidget {
  final String userNik;
  final Map<String, dynamic> config;
  const BayarIuranScreen({super.key, required this.userNik, required this.config});

  @override
  State<BayarIuranScreen> createState() => _BayarIuranScreenState();
}

class _BayarIuranScreenState extends State<BayarIuranScreen> {
  final Color primaryTeal = const Color(0xFF0F766E);
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajib upload bukti bayar!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Ambil User ID
      final user = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('nik', widget.userNik)
          .single();
      final userId = user['id'];

      // 2. Upload Bukti Bayar
      final fileName = 'proof_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'payments/$fileName';
      
      await Supabase.instance.client.storage
          .from('bukti_iuran')
          .upload(path, _selectedImage!);

      final imageUrl = Supabase.instance.client.storage
          .from('bukti_iuran')
          .getPublicUrl(path);

      // 3. Simpan Transaksi
      await Supabase.instance.client.from('pembayaran_iuran').insert({
        'user_id': userId,
        'kategori_id': widget.config['id'],
        'bulan': _selectedMonth,
        'tahun': _selectedYear,
        'jumlah_bayar': widget.config['nominal'],
        'bukti_bay_url': imageUrl,
        'status': 'pending'
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan pembayaran dikirim, tunggu verifikasi Admin'), backgroundColor: Colors.blue)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: true,
        title: const Text('BAYAR IURAN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 32),
            const Text('PILIH PERIODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        items: [DateTime.now().year, DateTime.now().year - 1].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('UPLOAD BUKTI TRANSFER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('SUBMIT PEMBAYARAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryTeal.withValues(alpha: 0.1))),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF0F766E)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.config['nama_iuran'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Nominal: Rp ${NumberFormat('#,###').format(widget.config['nominal'])}', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.values[0]),
          image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
        ),
        child: _selectedImage == null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: primaryTeal.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            const Text('Klik untuk pilih foto', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ) : null,
      ),
    );
  }
}
