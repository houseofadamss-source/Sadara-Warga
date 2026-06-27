import 'package:equatable/equatable.dart';
import '../../domain/entities/announcement_entity.dart';

abstract class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();

  @override
  List<Object> get props => [];
}

class FetchAnnouncementsRequested extends AnnouncementEvent {
  final String tipe;
  const FetchAnnouncementsRequested(this.tipe);

  @override
  List<Object> get props => [tipe];
}

class AddAnnouncementRequested extends AnnouncementEvent {
  final AnnouncementEntity announcement;
  const AddAnnouncementRequested(this.announcement);

  @override
  List<Object> get props => [announcement];
}

class UpdateAnnouncementRequested extends AnnouncementEvent {
  final AnnouncementEntity announcement;
  const UpdateAnnouncementRequested(this.announcement);

  @override
  List<Object> get props => [announcement];
}

class DeleteAnnouncementRequested extends AnnouncementEvent {
  final String id;
  const DeleteAnnouncementRequested(this.id);

  @override
  List<Object> get props => [id];
}

class ToggleFeaturedRequested extends AnnouncementEvent {
  final String id;
  final bool currentStatus;
  const ToggleFeaturedRequested(this.id, this.currentStatus);

  @override
  List<Object> get props => [id, currentStatus];
}
