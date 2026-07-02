import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;

class SuratPreviewDebugPage extends StatelessWidget {
  const SuratPreviewDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PREVIEW DESIGN SURAT', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: "surat_pengantar_resmi.pdf",
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    await initializeDateFormatting('id_ID', null);
    final pdf = pw.Document();

    // --- LOAD LOGO DARI ASSET LOKAL ---
    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load('assets/images/logo_bogor.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo tidak ditemukan, render tanpa logo. Pastikan ada di assets/images/logo_bogor.png');
    }

    // Data Mock buat Testing
    const String namaWarga = "ADHI PUTRA";
    const String nikWarga = "3201152209910001";
    const String ttl = "Bogor, 22 September 1991";
    const String gender = "Laki-laki";
    const String agama = "Islam";
    const String statusKawin = "Kawin";
    const String pekerjaan = "Karyawan Swasta";
    const String wargaNegara = "Indonesia";
    const String alamat = "Kp. Sinagar RT 03/06 Desa Cihideung Udik";
    const String keperluan = "Pembuatan Kartu Tanda Penduduk (KTP) Baru";
    const String nomorSurat = "001/RT03-RW06/VII/2026";
    final String tglSekarang = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- KOP SURAT ---
              pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  if (logoImage != null)
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logoImage, width: 60, height: 60),
                    ),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text("PEMERINTAH KABUPATEN BOGOR", 
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text("KECAMATAN CIAMPEA", 
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text("DESA CIHIDEUNG UDIK", 
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text("RUKUN TETANGGA (RT. 003) RUKUN WARGA (RW.006)", 
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Alamat: Kp. Sinagar RT 003/006 Desa Cihideung Udik Ciampea - Bogor, Bogor", 
                          style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Container(height: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 1),
              pw.Container(height: 0.8, color: PdfColors.black),
              pw.SizedBox(height: 20),

              // --- JUDUL SURAT ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("SURAT PENGANTAR", 
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.Text("No. : $nomorSurat", style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text("Yang bertanda tangan dibawah ini Ketua RT 003 RW 006 Desa Cihideung Udik Kecamatan Ciampea Kabupaten Bogor, menerangkan bahwa :",
                style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.justify),
              pw.SizedBox(height: 20),

              // --- DATA WARGA ---
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 40),
                child: pw.Column(
                  children: [
                    _pdfRow("Nama", namaWarga),
                    _pdfRow("Tempat/Tanggal/Lahir", ttl),
                    _pdfRow("Jenis Kelamin", gender),
                    _pdfRow("No. KTP/KK", nikWarga),
                    _pdfRow("Agama", agama),
                    _pdfRow("Status Perkawinan", statusKawin),
                    _pdfRow("Pekerjaan", pekerjaan),
                    _pdfRow("Kewarganegaraan", wargaNegara),
                    _pdfRow("Tempat Tinggal", alamat),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text("Nama tersebut diatas adalah benar warga RT 003 RW 006 Desa Cihideung Udik Kecamatan Ciampea Kabupaten Bogor, yang bermaksud memohon/mengurus :",
                style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.justify),
              
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Container(
                  width: 350,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5, style: pw.BorderStyle.dashed))),
                  child: pw.Center(child: pw.Text(keperluan, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                ),
              ),
              
              pw.SizedBox(height: 20),
              pw.Text("Demikian Surat Keterangan ini dibuat sebagai pengantar, dan untuk dipergunakan sebagaimana mestinya.",
                style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.justify),

              pw.Spacer(),

              // --- TANDA TANGAN ---
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Cihideung Udik, $tglSekarang", style: const pw.TextStyle(fontSize: 11))),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text("Ketua RW 006", style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 60),
                      pw.Text("Bpk. Sukma Miharja", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: "https://sadarawarga.com/verify/abc-123",
                    width: 50,
                    height: 50,
                  ),
                  pw.Column(
                    children: [
                      pw.Text("Ketua RT 003 RW 006", style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 60),
                      pw.Text("Bpk. Ade Mulyana", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                ]
              ),
              pw.SizedBox(height: 30),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: const pw.TextStyle(fontSize: 11))),
          pw.SizedBox(width: 10, child: pw.Text(":", style: const pw.TextStyle(fontSize: 11))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}
