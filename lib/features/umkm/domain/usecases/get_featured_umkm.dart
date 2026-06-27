import '../entities/umkm_entity.dart';
import '../repositories/umkm_repository.dart';

class GetFeaturedUmkm {
  final UmkmRepository repository;

  GetFeaturedUmkm(this.repository);

  Stream<List<UmkmEntity>> call() {
    return repository.getFeaturedUmkm();
  }
}
