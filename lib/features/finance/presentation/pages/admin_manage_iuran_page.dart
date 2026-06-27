import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/finance_entities.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

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

class AdminManageIuranPage extends StatelessWidget {
  const AdminManageIuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceBloc>()..add(FetchAdminFinanceData()),
      child: const AdminManageIuranView(),
    );
  }
}

class AdminManageIuranView extends StatefulWidget {
  const AdminManageIuranView({super.key});

  @override
  State<AdminManageIuranView> createState() => _AdminManageIuranViewState();
}

class _AdminManageIuranViewState extends State<AdminManageIuranView> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.all(Radius.circular(10))))),
              const SizedBox(height: 24),
              const Text('Buat Tagihan Iuran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildField('Nama Iuran', 'Contoh: Iuran Sampah Juli', _nameCtrl),
              const SizedBox(height: 16),
              _buildField('Nominal (Rp)', 'Contoh: 25000', _amountCtrl, keyboardType: TextInputType.number, isCurrency: true),
              const SizedBox(height: 16),
              _buildField('Deskripsi (Opsional)', 'Detail iuran...', _descCtrl, maxLines: 2),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final int val = int.parse(_amountCtrl.text.replaceAll('.', ''));
                    context.read<FinanceBloc>().add(AddBillCategoryRequested(_nameCtrl.text.trim(), val));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('BUAT TAGIHAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1, bool isCurrency = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl, 
          keyboardType: keyboardType, 
          maxLines: maxLines,
          inputFormatters: isCurrency ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] : null,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('MANAJEMEN IURAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is FinanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          List<BillEntity> categories = [];
          if (state is AdminFinanceLoaded) {
            categories = state.allCategories;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DAFTAR TAGIHAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 8),
                      const Text(
                        'Buat kategori iuran rutin atau sumbangan insidental. Nonaktifkan tagihan yang sudah tidak berlaku agar tidak muncul di warga.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (categories.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('Belum ada tagihan iuran.')))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = categories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(cat.namaIuran, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark), overflow: TextOverflow.ellipsis),
                            subtitle: Text('Rp ${NumberFormat('#,###', 'id_ID').format(cat.nominal)}', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                            trailing: Switch(
                              value: cat.isActive,
                              activeThumbColor: primaryTeal,
                              activeTrackColor: primaryTeal.withValues(alpha: 0.2),
                              onChanged: (val) {
                                context.read<FinanceBloc>().add(ToggleBillStatusRequested(cat.id, val));
                              },
                            ),
                          ),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddModal(context),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('BUAT TAGIHAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
