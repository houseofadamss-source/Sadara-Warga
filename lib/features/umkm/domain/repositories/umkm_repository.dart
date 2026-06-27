import 'package:dartz/dartz.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../entities/umkm_entity.dart';

abstract class UmkmRepository {
  // Ambil UMKM unggulan untuk beranda
  Stream<List<UmkmEntity>> getFeaturedUmkm();

  // Ambil semua UMKM terverifikasi
  Future<Either<Failure, List<UmkmEntity>>> getAllApprovedUmkm();

  // Ambil UMKM berdasarkan status (untuk admin)
  Stream<List<UmkmEntity>> getUmkmByStatus(String status);

  // Daftarkan UMKM baru
  Future<Either<Failure, Unit>> registerUmkm(UmkmEntity umkm);

  // Update status (Admin)
  Future<Either<Failure, Unit>> updateUmkmStatus(String id, String status);

  // Toggle Featured (Admin)
  Future<Either<Failure, Unit>> toggleFeatured(String id, bool currentVal);

  // Push to OSM
  Future<Either<Failure, Unit>> pushToOsm(UmkmEntity umkm);
}
