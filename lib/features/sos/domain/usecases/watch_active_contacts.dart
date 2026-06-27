import '../entities/emergency_entity.dart';
import '../repositories/emergency_repository.dart';

class WatchActiveContacts {
  final EmergencyRepository repository;

  WatchActiveContacts(this.repository);

  Stream<List<EmergencyEntity>> call() {
    return repository.watchActiveContacts();
  }
}
