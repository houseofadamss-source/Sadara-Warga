import '../../domain/entities/version_entity.dart';

class VersionModel extends VersionEntity {
  const VersionModel({
    required super.versionName,
    required super.releaseDate,
    required super.changelog,
    super.downloadUrl,
  });

  factory VersionModel.fromGithubJson(Map<String, dynamic> json) {
    String? downloadUrl;
    if (json['assets'] != null && (json['assets'] as List).isNotEmpty) {
      downloadUrl = json['assets'][0]['browser_download_url'];
    }

    return VersionModel(
      versionName: (json['tag_name'] as String).replaceAll('v', ''),
      releaseDate: json['published_at'] ?? DateTime.now().toIso8601String(),
      changelog: json['body'] ?? '',
      downloadUrl: downloadUrl,
    );
  }

  static List<VersionModel> fromGithubJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => VersionModel.fromGithubJson(e)).toList();
  }
}
