import 'package:equatable/equatable.dart';
import '../../domain/entities/umkm_entity.dart';

abstract class UmkmState extends Equatable {
  const UmkmState();
  
  @override
  List<Object?> get props => [];
}

class UmkmInitial extends UmkmState {}

class UmkmLoading extends UmkmState {}

class UmkmLoaded extends UmkmState {
  final List<UmkmEntity> umkmList;
  const UmkmLoaded(this.umkmList);

  @override
  List<Object?> get props => [umkmList];
}

class UmkmActionSuccess extends UmkmState {
  final String message;
  const UmkmActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UmkmFailure extends UmkmState {
  final String message;
  const UmkmFailure(this.message);

  @override
  List<Object?> get props => [message];
}
