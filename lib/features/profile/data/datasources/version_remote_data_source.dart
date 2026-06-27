import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/version_model.dart';

abstract class VersionRemoteDataSource {
  Future<List<VersionModel>> getVersionsFromGithub();
}

class VersionRemoteDataSourceImpl implements VersionRemoteDataSource {
  final http.Client client;
  static const String _repoUrl = 'https://api.github.com/repos/houseofadamss-source/Sadara-Warga/releases';

  VersionRemoteDataSourceImpl({required this.client});

  @override
  Future<List<VersionModel>> getVersionsFromGithub() async {
    final response = await client.get(Uri.parse(_repoUrl));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return VersionModel.fromGithubJsonList(data);
    } else {
      throw Exception('Gagal memuat catatan rilis dari GitHub');
    }
  }
}
