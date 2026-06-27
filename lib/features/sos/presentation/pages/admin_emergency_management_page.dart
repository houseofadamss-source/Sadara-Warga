import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/emergency_entity.dart';
import '../bloc/sos_bloc.dart';
import '../bloc/sos_event.dart';
import '../bloc/sos_state.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class AdminEmergencyManagementPage extends StatelessWidget {
  const AdminEmergencyManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SosBloc>()..add(FetchAllContactsRequested()),
      child: const AdminEmergencyManagementView(),
    );
  }
}

class AdminEmergencyManagementView extends StatelessWidget {
  const AdminEmergencyManagementView({super.key});

  void _showStatusDialog(BuildContext context, {required bool isSuccess, required String message}) {
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

  void _showContactForm(BuildContext context, {EmergencyEntity? contact}) {
    final isEdit = contact != null;
    final titleController = TextEditingController(text: contact?.title ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final descController = TextEditingController(text: contact?.description ?? '');
    String selectedCategory = contact?.category ?? 'pengurus';
    String selectedAction = contact?.actionType ?? 'call';
    bool isActive = contact?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, setModalState) => Container(
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
                    onPressed: () {
                      if (titleController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                        _showStatusDialog(context, isSuccess: false, message: 'Harap isi Nama dan Nomor telepon kontak.');
                        return;
                      }

                      final newContact = EmergencyEntity(
                        id: contact?.id,
                        category: selectedCategory,
                        title: titleController.text.trim(),
                        phone: phoneController.text.trim(),
                        description: descController.text.trim(),
                        actionType: selectedAction,
                        isActive: isActive,
                      );

                      context.read<SosBloc>().add(SaveContactRequested(newContact));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAHKAN KONTAK', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isEdit) ...[
                   const SizedBox(height: 12),
                   TextButton(
                     onPressed: () {
                        context.read<SosBloc>().add(DeleteContactRequested(contact.id!));
                        Navigator.pop(context);
                     },
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
      body: BlocConsumer<SosBloc, SosState>(
        listener: (context, state) {
          if (state is SosActionSuccess) {
            _showStatusDialog(context, isSuccess: true, message: state.message);
            context.read<SosBloc>().add(FetchAllContactsRequested());
          } else if (state is SosFailure) {
            _showStatusDialog(context, isSuccess: false, message: state.message);
          }
        },
        builder: (context, state) {
          if (state is SosLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          List<EmergencyEntity> contacts = [];
          if (state is SosLoaded) {
            contacts = state.contacts;
          }

          if (contacts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return _buildContactCard(context, contacts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactForm(context),
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

  Widget _buildContactCard(BuildContext context, EmergencyEntity item) {
    final isActive = item.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.transparent : Colors.red.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: () => _showContactForm(context, contact: item),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getIconForCategory(item.category), color: primaryTeal),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        subtitle: Text(item.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
