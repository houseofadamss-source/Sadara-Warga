import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/surat_entity.dart';
import '../bloc/surat_bloc.dart';
import '../bloc/surat_event.dart';
import '../bloc/surat_state.dart';

class SuratFormPage extends StatelessWidget {
  final String nik;
  final String nama;
  final String jenisSurat;
  const SuratFormPage({super.key, required this.nik, required this.nama, required this.jenisSurat});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SuratBloc>(),
      child: SuratFormView(nik: nik, nama: nama, jenisSurat: jenisSurat),
    );
  }
}

class SuratFormView extends StatefulWidget {
  final String nik;
  final String nama;
  final String jenisSurat;
  const SuratFormView({super.key, required this.nik, required this.nama, required this.jenisSurat});

  @override
  State<SuratFormView> createState() => _SuratFormViewState();
}

class _SuratFormViewState extends State<SuratFormView> {
  final _ttlCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _keperluanCtrl = TextEditingController();
  
  String _selectedGender = 'Laki-laki';
  String _selectedAgama = 'Islam';
  String _selectedStatus = 'Kawin';
  String _selectedWarganegara = 'Indonesia';

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _agamas = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Budha', 'Konghucu'];
  final List<String> _statuses = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];
  final List<String> _nationalities = ['Indonesia', 'WNA'];

  void _onSubmitPressed(BuildContext context) {
    final String ttl = _ttlCtrl.text.trim();
    final String pekerjaan = _pekerjaanCtrl.text.trim();
    final String alamat = _alamatCtrl.text.trim();
    final String keperluan = _keperluanCtrl.text.trim();

    if (ttl.isEmpty || pekerjaan.isEmpty || alamat.isEmpty || keperluan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final surat = SuratEntity(
      id: const Uuid().v4(),
      userId: user.id,
      nik: widget.nik,
      namaLengkap: widget.nama,
      jenisSurat: widget.jenisSurat,
      ttl: ttl,
      jenisKelamin: _selectedGender,
      agama: _selectedAgama,
      statusPerkawinan: _selectedStatus,
      pekerjaan: pekerjaan,
      tempatTinggal: alamat,
      keperluan: keperluan,
      status: 'pending',
      kewarganegaraan: _selectedWarganegara,
      createdAt: DateTime.now(),
    );

    context.read<SuratBloc>().add(SubmitSuratRequested(surat));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return BlocListener<SuratBloc, SuratState>(
      listener: (context, state) {
        if (state is SuratActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          Navigator.pop(context);
        } else if (state is SuratFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0, centerTitle: true,
          title: Text(widget.jenisSurat.toUpperCase(), style: const TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
          leading: IconButton(icon: const Icon(Icons.close, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informasi Pemohon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              const Text('Lengkapi data di bawah ini. Data ini akan tercantum dalam surat resmi Anda.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 32),
              
              _buildLabel('NAMA LENGKAP'),
              _buildReadOnlyField(widget.nama),
              const SizedBox(height: 24),
              
              _buildLabel('NOMOR NIK'),
              _buildReadOnlyField(widget.nik),
              const SizedBox(height: 24),

              _buildLabel('TEMPAT, TANGGAL LAHIR'),
              _buildTextField('Misal: Jakarta, 17-08-1945', _ttlCtrl),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('JENIS KELAMIN'), _buildDropdown(_genders, _selectedGender, (v) => setState(() => _selectedGender = v!))])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('AGAMA'), _buildDropdown(_agamas, _selectedAgama, (v) => setState(() => _selectedAgama = v!))])),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('STATUS PERKAWINAN'),
              _buildDropdown(_statuses, _selectedStatus, (v) => setState(() => _selectedStatus = v!)),
              const SizedBox(height: 24),

              _buildLabel('PEKERJAAN'),
              _buildTextField('Misal: Karyawan Swasta', _pekerjaanCtrl),
              const SizedBox(height: 24),

              _buildLabel('KEWARGANEGARAAN'),
              _buildDropdown(_nationalities, _selectedWarganegara, (v) => setState(() => _selectedWarganegara = v!)),
              const SizedBox(height: 24),

              _buildLabel('ALAMAT TINGGAL (SESUAI DOMISILI)'),
              _buildTextField('Isi alamat lengkap Anda saat ini...', _alamatCtrl, maxLines: 2),
              const SizedBox(height: 24),

              _buildLabel('KEPERLUAN SURAT'),
              _buildTextField('Misal: Syarat membuat Akta Kelahiran anak', _keperluanCtrl, maxLines: 3),
              const SizedBox(height: 48),

              BlocBuilder<SuratBloc, SuratState>(
                builder: (context, state) {
                  final bool isLoading = state is SuratLoading;
                  return SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _onSubmitPressed(context),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                      child: isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('AJUKAN SURAT SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5)));

  Widget _buildReadOnlyField(String text) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)), child: Text(text, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14)));

  Widget _buildTextField(String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl, maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.black12, fontSize: 14), 
        filled: true, fillColor: const Color(0xFFF8FAFC), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), 
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F766E))),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, 
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)))).toList(), 
          onChanged: onChanged, 
          isExpanded: true
        ),
      ),
    );
  }
}
