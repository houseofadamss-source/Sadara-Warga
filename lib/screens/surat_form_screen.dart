import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuratFormScreen extends StatefulWidget {
  final String nik;
  final String nama;
  const SuratFormScreen({super.key, required this.nik, required this.nama});

  @override
  State<SuratFormScreen> createState() => _SuratFormScreenState();
}

class _SuratFormScreenState extends State<SuratFormScreen> {
  final _ttlCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _keperluanCtrl = TextEditingController();
  
  String _selectedGender = 'Laki-laki';
  String _selectedAgama = 'Islam';
  String _selectedStatus = 'Kawin';
  bool _isLoading = false;

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _agamas = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Budha', 'Konghucu'];
  final List<String> _statuses = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];

  Future<void> _submitSurat() async {
    if (_ttlCtrl.text.isEmpty || _pekerjaanCtrl.text.isEmpty || _alamatCtrl.text.isEmpty || _keperluanCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('surat_pengantar').insert({
        'nik': widget.nik,
        'nama_lengkap': widget.nama,
        'ttl': _ttlCtrl.text.trim(),
        'jenis_kelamin': _selectedGender,
        'agama': _selectedAgama,
        'status_perkawinan': _selectedStatus,
        'pekerjaan': _pekerjaanCtrl.text.trim(),
        'tempat_tinggal': _alamatCtrl.text.trim(),
        'keperluan': _keperluanCtrl.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan berhasil! Silakan tunggu konfirmasi RT.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('FORM SURAT PENGANTAR', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14)),
        leading: IconButton(icon: const Icon(Icons.close, color: textDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Pemohon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            const Text('Data ini akan digunakan untuk mencetak surat pengantar Anda secara otomatis.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 32),
            
            _buildLabel('Nama Lengkap (Sesuai KTP)'),
            _buildReadOnlyField(widget.nama),
            const SizedBox(height: 20),
            
            _buildLabel('NIK'),
            _buildReadOnlyField(widget.nik),
            const SizedBox(height: 20),

            _buildLabel('Tempat, Tanggal Lahir'),
            _buildTextField('Contoh: Bogor, 12-05-1990', _ttlCtrl),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Jenis Kelamin'), _buildDropdown(_genders, _selectedGender, (v) => setState(() => _selectedGender = v!))])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Agama'), _buildDropdown(_agamas, _selectedAgama, (v) => setState(() => _selectedAgama = v!))])),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel('Status Perkawinan'),
            _buildDropdown(_statuses, _selectedStatus, (v) => setState(() => _selectedStatus = v!)),
            const SizedBox(height: 20),

            _buildLabel('Pekerjaan'),
            _buildTextField('Contoh: Karyawan Swasta', _pekerjaanCtrl),
            const SizedBox(height: 20),

            _buildLabel('Tempat Tinggal (Alamat Lengkap)'),
            _buildTextField('Isi alamat sesuai domisili saat ini', _alamatCtrl, maxLines: 2),
            const SizedBox(height: 20),

            _buildLabel('Jenis Keperluan (Memohon/Mengurus)'),
            _buildTextField('Contoh: Pembuatan KK baru karena pindah datang', _keperluanCtrl, maxLines: 3),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSurat,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('AJUKAN SURAT SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))));

  Widget _buildReadOnlyField(String text) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)));

  Widget _buildTextField(String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200))),
    );
  }

  Widget _buildDropdown(List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, isExpanded: true),
      ),
    );
  }
}
