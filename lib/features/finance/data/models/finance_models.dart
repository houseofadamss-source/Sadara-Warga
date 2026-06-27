import '../../domain/entities/finance_entities.dart';

class KasModel extends KasEntity {
  const KasModel({required super.totalSaldo, super.googleDocUrl});

  factory KasModel.fromJson(Map<String, dynamic> json) {
    return KasModel(
      totalSaldo: json['total_saldo'] ?? 0,
      googleDocUrl: json['google_doc_url'],
    );
  }
}

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.namaIuran,
    required super.nominal,
    required super.isActive,
    super.totalPaid,
    super.sisa,
    super.isLunas,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'].toString(),
      namaIuran: json['nama_iuran'] ?? '-',
      nominal: json['nominal'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_iuran': namaIuran,
      'nominal': nominal,
      'is_active': isActive,
    };
  }
}

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.userId,
    required super.kategoriId,
    required super.jumlahBayar,
    required super.bulan,
    required super.tahun,
    required super.status,
    required super.createdAt,
    super.buktiUrl,
    super.kategoriName,
    super.userName,
    super.userAddress,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      userId: json['user_id'],
      kategoriId: json['kategori_id'].toString(),
      jumlahBayar: json['jumlah_bayar'] ?? 0,
      bulan: json['bulan'] ?? 1,
      tahun: json['tahun'] ?? 2024,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      buktiUrl: json['bukti_transfer'] ?? json['bukti_transfer_url'],
      userName: json['users'] != null ? json['users']['nama_lengkap'] : null,
      userAddress: json['users'] != null ? json['users']['alamat'] : null,
    );
  }

  static List<PaymentModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => PaymentModel.fromJson(item)).toList();
  }
}

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.judul,
    required super.nominal,
    required super.tanggal,
    super.keterangan,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'].toString(),
      judul: json['judul_pengeluaran'] ?? '-',
      nominal: json['nominal'] ?? 0,
      tanggal: DateTime.parse(json['tanggal_pengeluaran']),
      keterangan: json['keterangan'],
    );
  }

  static List<ExpenseModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => ExpenseModel.fromJson(item)).toList();
  }
}
