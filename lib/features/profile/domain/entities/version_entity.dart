import 'package:equatable/equatable.dart';

class VersionEntity extends Equatable {
  final String versionName;
  final String releaseDate;
  final String changelog;
  final String? downloadUrl;

  const VersionEntity({
    required this.versionName,
    required this.releaseDate,
    required this.changelog,
    this.downloadUrl,
  });

  @override
  List<Object?> get props => [versionName, releaseDate, changelog, downloadUrl];
}
