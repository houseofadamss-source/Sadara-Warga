import 'package:equatable/equatable.dart';
import '../../domain/entities/announcement_entity.dart';

abstract class AnnouncementState extends Equatable {
  const AnnouncementState();
  
  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {}

class AnnouncementLoading extends AnnouncementState {}

class AnnouncementsLoaded extends AnnouncementState {
  final List<AnnouncementEntity> announcements;
  const AnnouncementsLoaded(this.announcements);

  @override
  List<Object?> get props => [announcements];
}

class AnnouncementActionSuccess extends AnnouncementState {
  final String message;
  const AnnouncementActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AnnouncementFailure extends AnnouncementState {
  final String message;
  const AnnouncementFailure(this.message);

  @override
  List<Object?> get props => [message];
}
