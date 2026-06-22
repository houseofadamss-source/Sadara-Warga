import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    final int value = int.parse(cleanText);
    final formatter = NumberFormat.decimalPattern('id');
    String newText = formatter.format(value);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

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
  final _amountCtrl = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    // Default nominal sesuai tagihan
    final formatter = NumberFormat.decimalPattern('id');
    _amountCtrl.text = formatter.format(widget.config['nominal'] ?? 0);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajib upload bukti bayar!'), backgroundColor: Colors.orange));
      return;
    }

    final String amountStr = _amountCtrl.text.replaceAll('.', '');
    if (amountStr.isEmpty || int.parse(amountStr) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal bayar tidak valid!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw 'Sesi berakhir, silakan login ulang.';

      // 1. Upload Foto Bukti
      final fileName = 'proof_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'payments/$fileName';
      
      await client.storage.from('bukti_iuran').upload(path, _selectedImage!);
      final imageUrl = client.storage.from('bukti_iuran').getPublicUrl(path);

      // 2. Simpan Transaksi (Mendukung Cicilan/Multiple Payment)
      await client.from('pembayaran_iuran').insert({
        'user_id': user.id,
        'kategori_id': widget.config['id'],
        'bulan': _selectedMonth,
        'tahun': _selectedYear,
        'jumlah_bayar': int.parse(amountStr),
        'bukti_transfer_url': imageUrl,
        'status': 'pending'
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil! Menunggu verifikasi Admin.'), backgroundColor: Color(0xFF0F766E))
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Gagal Kirim'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: true,
        title: const Text('LAPOR PEMBAYARAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 32),
            
            const Text('NOMINAL YANG DIBAYARKAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('*Anda bisa mengubah nominal di atas jika ingin mencicil.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),

            const SizedBox(height: 32),
            const Text('PERIODE PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        items: [DateTime.now().year, DateTime.now().year - 1].map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)))).toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('UNGGAH BUKTI TRANSFER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('KIRIM KONFIRMASI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: primaryTeal.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.info_outline_rounded, color: Color(0xFF0F766E), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.config['nama_iuran'] ?? 'Iuran Bulanan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('TAGIHAN BULAN INI', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Rp ${NumberFormat('#,###', 'id_ID').format(widget.config['nominal'])}', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 220,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
          image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: _selectedImage == null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, size: 48, color: primaryTeal.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            const Text('Klik untuk ambil foto struk/screenshot', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ) : null,
      ),
    );
  }
}
