import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/report_entity.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class AddReportPage extends StatelessWidget {
  final String nik;
  final String nama;
  const AddReportPage({super.key, required this.nik, required this.nama});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportBloc>(),
      child: AddReportView(nik: nik, nama: nama),
    );
  }
}

class AddReportView extends StatefulWidget {
  final String nik;
  final String nama;
  const AddReportView({super.key, required this.nik, required this.nama});

  @override
  State<AddReportView> createState() => _AddReportViewState();
}

class _AddReportViewState extends State<AddReportView> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _selectedKategori = 'Umum';
  File? _imageFile;
  Position? _currentPosition;
  final _picker = ImagePicker();

  final List<String> _kategoriList = ['Umum', 'Keamanan', 'Kebersihan', 'Infrastruktur', 'Sosial'];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) { /* ignore */ }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _onSubmitPressed(BuildContext context) {
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Deskripsi harus diisi!')));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final report = ReportEntity(
      id: const Uuid().v4(),
      userId: user.id,
      namaWarga: widget.nama,
      judulLaporan: _judulController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      kategori: _selectedKategori,
      status: 'Menunggu',
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      createdAt: DateTime.now(),
    );

    context.read<ReportBloc>().add(SubmitReportRequested(report, _imageFile?.path));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          Navigator.pop(context, true);
        } else if (state is ReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0, centerTitle: true,
          title: const Text('Buat Laporan', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, height: 200,
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: _imageFile != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 40, color: primaryTeal), SizedBox(height: 12), Text('Ambil Foto Kejadian', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(height: 24),
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
                        decoration: BoxDecoration(color: isSelected ? primaryTeal : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
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
              BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  final bool isLoading = state is ReportLoading;
                  return SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _onSubmitPressed(context),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('KIRIM LAPORAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))));
  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14), fillColor: const Color(0xFFF8FAFC), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F766E)))),
    );
  }
}
