import 'package:equatable/equatable.dart';

class KasEntity extends Equatable {
  final int totalSaldo;
  final String? googleDocUrl;

  const KasEntity({required this.totalSaldo, this.googleDocUrl});

  @override
  List<Object?> get props => [totalSaldo, googleDocUrl];
}

class BillEntity extends Equatable {
  final String id;
  final String namaIuran;
  final int nominal;
  final bool isActive;
  final int totalPaid;
  final int sisa;
  final bool isLunas;

  const BillEntity({
    required this.id,
    required this.namaIuran,
    required this.nominal,
    required this.isActive,
    this.totalPaid = 0,
    this.sisa = 0,
    this.isLunas = false,
  });

  @override
  List<Object?> get props => [id, namaIuran, nominal, isActive, totalPaid, sisa, isLunas];
}

class PaymentEntity extends Equatable {
  final String id;
  final String userId;
  final String kategoriId;
  final int jumlahBayar;
  final int bulan;
  final int tahun;
  final String status;
  final DateTime createdAt;
  final String? buktiUrl;
  final String? kategoriName;
  final String? userName;
  final String? userAddress;

  const PaymentEntity({
    required this.id,
    required this.userId,
    required this.kategoriId,
    required this.jumlahBayar,
    required this.bulan,
    required this.tahun,
    required this.status,
    required this.createdAt,
    this.buktiUrl,
    this.kategoriName,
    this.userName,
    this.userAddress,
  });

  @override
  List<Object?> get props => [id, userId, kategoriId, jumlahBayar, bulan, tahun, status, createdAt, buktiUrl, kategoriName, userName, userAddress];
}

class ExpenseEntity extends Equatable {
  final String id;
  final String judul;
  final int nominal;
  final DateTime tanggal;
  final String? keterangan;

  const ExpenseEntity({
    required this.id,
    required this.judul,
    required this.nominal,
    required this.tanggal,
    this.keterangan,
  });

  @override
  List<Object?> get props => [id, judul, nominal, tanggal, keterangan];
}
