import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddEventScreen extends StatefulWidget {
  final Map<String, dynamic>? eventData;
  const AddEventScreen({super.key, this.eventData});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _picNameCtrl = TextEditingController();
  final _picPhoneCtrl = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 08, minute: 00);
  
  File? _imageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

  // Maps State
  LatLng _selectedLoc = const LatLng(-6.579545, 106.7162769); // Default Sinagar
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) {
      final ev = widget.eventData!;
      _titleCtrl.text = ev['title'] ?? '';
      _descCtrl.text = ev['description'] ?? '';
      _locCtrl.text = ev['location'] ?? '';
      _picNameCtrl.text = ev['coordinator_name'] ?? '';
      _picPhoneCtrl.text = ev['coordinator_phone'] ?? '';
      _selectedDate = DateTime.parse(ev['event_date']);
      
      if (ev['event_time'] != null) {
        final timeParts = (ev['event_time'] as String).split(':');
        _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }

      if (ev['latitude'] != null && ev['longitude'] != null) {
        _selectedLoc = LatLng(ev['latitude'], ev['longitude']);
      }
    } else {
      _determineInitialLocation();
    }
  }

  Future<void> _determineInitialLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLoc = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_selectedLoc, 16);
      });
    } catch (e) { /* ignore */ }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveEvent() async {
    if (_titleCtrl.text.isEmpty || _locCtrl.text.isEmpty || _picPhoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul, Lokasi, dan No WA wajib diisi!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl = widget.eventData?['image_url'];
      if (_imageFile != null) {
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('announcements').upload(fileName, _imageFile!);
        imageUrl = Supabase.instance.client.storage.from('announcements').getPublicUrl(fileName);
      }

      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        'latitude': _selectedLoc.latitude,
        'longitude': _selectedLoc.longitude,
        'coordinator_name': _picNameCtrl.text.trim(),
        'coordinator_phone': _picPhoneCtrl.text.trim(),
        'event_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'event_time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'image_url': imageUrl,
        'status': 'aktif',
      };

      if (widget.eventData == null) {
        await Supabase.instance.client.from('events').insert(data);
      } else {
        await Supabase.instance.client.from('events').update(data).eq('id', widget.eventData!['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acara berhasil disimpan!'), backgroundColor: Color(0xFF0F766E)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
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
        title: Text(widget.eventData == null ? 'TAMBAH ACARA' : 'EDIT ACARA', style: const TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.close, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 180,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: _imageFile != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_imageFile!, fit: BoxFit.cover))
                  : (widget.eventData?['image_url'] != null 
                      ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(widget.eventData!['image_url'], fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 40, color: primaryTeal), SizedBox(height: 8), Text('Tambah Foto Acara', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold))])),
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel('JUDUL KEGIATAN'),
            _buildTextField('Misal: Rapat Bulanan Warga', _titleCtrl),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('TANGGAL'), _buildPickerTile(DateFormat('dd MMM yyyy').format(_selectedDate), Icons.calendar_month_rounded, _selectDate)])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('WAKTU'), _buildPickerTile(_selectedTime.format(context), Icons.access_time_filled_rounded, _selectTime)])),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabel('LOKASI (DESKRIPSI TEKS)'),
            _buildTextField('Contoh: Balai Warga RT 03', _locCtrl),
            const SizedBox(height: 24),
            
            _buildLabel('TENTUKAN TITIK LOKASI (MAPS)'),
            const SizedBox(height: 12),
            Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLoc,
                    initialZoom: 16,
                    onTap: (tapPos, latLng) => setState(() => _selectedLoc = latLng),
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.sadarawarga.app'),
                    MarkerLayer(
                      markers: [
                        Marker(point: _selectedLoc, width: 40, height: 40, child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('*Klik pada peta untuk memindahkan Pin lokasi acara.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
            ),
            
            const SizedBox(height: 24),
            _buildLabel('DESKRIPSI ACARA'),
            _buildTextField('Tulis detail kegiatan...', _descCtrl, maxLines: 4),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text('INFORMASI KONTAK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 20),
            _buildLabel('NAMA PENANGGUNG JAWAB'),
            _buildTextField('Nama PIC / Ketua Panitia', _picNameCtrl),
            const SizedBox(height: 20),
            _buildLabel('NOMOR WHATSAPP'),
            _buildTextField('0812xxxxxxxx', _picPhoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('TERBITKAN ACARA SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5)));

  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller, maxLines: maxLines, keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.black12, fontSize: 14),
        fillColor: const Color(0xFFF8FAFC), filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F766E))),
      ),
    );
  }

  Widget _buildPickerTile(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), 
        child: Row(children: [Icon(icon, size: 20, color: const Color(0xFF0F766E)), const SizedBox(width: 12), Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))])
      ),
    );
  }
}
