import 'package:equatable/equatable.dart';
import '../../domain/entities/umkm_entity.dart';

abstract class UmkmEvent extends Equatable {
  const UmkmEvent();

  @override
  List<Object> get props => [];
}

class FetchApprovedUmkm extends UmkmEvent {}

class RegisterUmkmRequested extends UmkmEvent {
  final UmkmEntity umkm;
  const RegisterUmkmRequested(this.umkm);

  @override
  List<Object> get props => [umkm];
}

class UpdateStatusRequested extends UmkmEvent {
  final String id;
  final String status;
  const UpdateStatusRequested(this.id, this.status);

  @override
  List<Object> get props => [id, status];
}

class ToggleFeaturedRequested extends UmkmEvent {
  final String id;
  final bool currentVal;
  const ToggleFeaturedRequested(this.id, this.currentVal);

  @override
  List<Object> get props => [id, currentVal];
}

class PushToOsmRequested extends UmkmEvent {
  final UmkmEntity umkm;
  const PushToOsmRequested(this.umkm);

  @override
  List<Object> get props => [umkm];
}
