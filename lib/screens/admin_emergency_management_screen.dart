import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class AdminEmergencyManagementScreen extends StatefulWidget {
  const AdminEmergencyManagementScreen({super.key});

  @override
  State<AdminEmergencyManagementScreen> createState() => _AdminEmergencyManagementScreenState();
}

class _AdminEmergencyManagementScreenState extends State<AdminEmergencyManagementScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final data = await Supabase.instance.client
          .from('emergency_contacts')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStatusDialog({required bool isSuccess, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isSuccess ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              isSuccess ? 'Berhasil!' : 'Terjadi Kesalahan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('OKE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactForm({Map<String, dynamic>? contact}) {
    final isEdit = contact != null;
    final titleController = TextEditingController(text: contact?['title'] ?? '');
    final phoneController = TextEditingController(text: contact?['phone'] ?? '');
    final descController = TextEditingController(text: contact?['description'] ?? '');
    String selectedCategory = contact?['category'] ?? 'pengurus';
    String selectedAction = contact?['action_type'] ?? 'call';
    bool isActive = contact?['is_active'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 32, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEdit ? 'Edit Kontak' : 'Tambah Kontak Baru',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('KATEGORI LAYANAN'),
                const SizedBox(height: 12),
                _buildCategorySelector(selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                const SizedBox(height: 24),
                _buildTextField(titleController, 'Nama Layanan/Pejabat', 'Contoh: Ambulans Desa, Ketua RT 01'),
                const SizedBox(height: 20),
                _buildTextField(phoneController, 'Nomor Telepon/WA', 'Contoh: 08123456789', isPhone: true),
                const SizedBox(height: 20),
                _buildTextField(descController, 'Keterangan Singkat', 'Contoh: Aktif 24 Jam'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Metode Hubungi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Call'),
                      selected: selectedAction == 'call',
                      onSelected: (val) => setModalState(() => selectedAction = 'call'),
                      selectedColor: primaryTeal.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('WhatsApp'),
                      selected: selectedAction == 'whatsapp',
                      onSelected: (val) => setModalState(() => selectedAction = 'whatsapp'),
                      selectedColor: primaryTeal.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Aktifkan Kontak ini?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Jika mati, warga tidak akan melihat kontak ini.', style: TextStyle(fontSize: 11)),
                  value: isActive,
                  activeThumbColor: primaryTeal,
                  onChanged: (val) => setModalState(() => isActive = val),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () async {
                      if (titleController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                        _showStatusDialog(isSuccess: false, message: 'Harap isi Nama dan Nomor telepon kontak.');
                        return;
                      }

                      setModalState(() => _isSaving = true);
                      final result = await _saveContact(
                        id: contact?['id'],
                        category: selectedCategory,
                        title: titleController.text.trim(),
                        phone: phoneController.text.trim(),
                        desc: descController.text.trim(),
                        action: selectedAction,
                        active: isActive,
                      );
                      setModalState(() => _isSaving = false);
                      
                      if (result && mounted) {
                        Navigator.pop(context);
                        _showStatusDialog(isSuccess: true, message: 'Kontak darurat berhasil diperbarui!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAHKAN KONTAK', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isEdit) ...[
                   const SizedBox(height: 12),
                   TextButton(
                     onPressed: () => _deleteContact(contact['id']),
                     child: const Center(child: Text('HAPUS KONTAK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                   )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(String current, Function(String) onSelected) {
    final categories = [
      {'id': 'medis', 'label': 'Medis', 'icon': Icons.medical_services_rounded},
      {'id': 'keamanan', 'label': 'Polisi', 'icon': Icons.local_police_rounded},
      {'id': 'damkar', 'label': 'Pemadam', 'icon': Icons.local_fire_department_rounded},
      {'id': 'pengurus', 'label': 'RT/RW', 'icon': Icons.supervisor_account_rounded},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        final isSelected = current == cat['id'];
        return GestureDetector(
          onTap: () => onSelected(cat['id'] as String),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryTeal : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey, size: 24),
              ),
              const SizedBox(height: 6),
              Text(cat['label'] as String, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryTeal : Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5));
  }

  Future<bool> _saveContact({dynamic id, required String category, required String title, required String phone, required String desc, required String action, required bool active}) async {
    try {
      final payload = {
        'category': category,
        'title': title,
        'phone': phone,
        'description': desc,
        'action_type': action,
        'is_active': active,
      };

      if (id != null) {
        await Supabase.instance.client.from('emergency_contacts').update(payload).eq('id', id);
      } else {
        await Supabase.instance.client.from('emergency_contacts').insert(payload);
      }

      await _fetchContacts();
      return true;
    } catch (e) {
      if (mounted) _showStatusDialog(isSuccess: false, message: 'Gagal menghubungi server: $e');
      return false;
    }
  }

  Future<void> _deleteContact(dynamic id) async {
    try {
      await Supabase.instance.client.from('emergency_contacts').delete().eq('id', id);
      if (mounted) {
        Navigator.pop(context);
        await _fetchContacts();
        _showStatusDialog(isSuccess: true, message: 'Kontak telah berhasil dihapus dari sistem.');
      }
    } catch (e) {
      if (mounted) _showStatusDialog(isSuccess: false, message: 'Gagal menghapus kontak: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kelola Kontak Darurat', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : _contacts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final item = _contacts[index];
                    return _buildContactCard(item);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactForm(),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add_call, color: Colors.white),
        label: const Text('TAMBAH KONTAK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Belum ada kontak darurat.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> item) {
    final isActive = item['is_active'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.transparent : Colors.red.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: () => _showContactForm(contact: item),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getIconForCategory(item['category']), color: primaryTeal),
        ),
        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        subtitle: Text(item['phone'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(isActive ? 'AKTIF' : 'MATI', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'medis': return Icons.medical_services_rounded;
      case 'keamanan': return Icons.local_police_rounded;
      case 'damkar': return Icons.local_fire_department_rounded;
      default: return Icons.supervisor_account_rounded;
    }
  }
}
