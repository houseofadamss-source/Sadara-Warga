import 'package:http/http.dart' as http;
import 'osm_auth_service.dart';

class OsmApiService {
  final OsmAuthService _authService = OsmAuthService();
  final String _baseUrl = 'https://api.openstreetmap.org/api/0.6';

  // JURUS ANTI-ERROR: Escape karakter khusus XML agar tidak crash saat kirim nama bisnis
  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Map<String, String> _mapCategoryToTags(String category) {
    if (category.contains('Kuliner')) return {'amenity': 'restaurant'};
    if (category.contains('Sembako')) return {'shop': 'convenience'};
    if (category.contains('Laundry')) return {'shop': 'laundry'};
    if (category.contains('Sayur')) return {'shop': 'greengrocer'};
    if (category.contains('Fashion')) return {'shop': 'clothes'};
    if (category.contains('Elektronik')) return {'shop': 'mobile_phone'};
    if (category.contains('Bengkel')) return {'shop': 'motorcycle_repair'};
    if (category.contains('Apotek')) return {'amenity': 'pharmacy'};
    if (category.contains('Kerajinan')) return {'shop': 'craft'};
    return {'shop': 'yes'};
  }

  Future<String?> _createChangeset(String token) async {
    final xml = """
    <osm>
      <changeset>
        <tag k="created_by" v="Sadara Warga App"/>
        <tag k="comment" v="Menambahkan UMKM Warga Kp. Sinagar RT 03"/>
      </changeset>
    </osm>
    """;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/changeset/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'text/xml',
        },
        body: xml,
      );

      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      print('OSM Changeset Error: $e');
    }
    return null;
  }

  Future<bool> pushToOsm(Map<String, dynamic> umkm) async {
    try {
      String? token = await _authService.getValidToken();
      token ??= await _authService.login();

      if (token == null) return false;

      final changesetId = await _createChangeset(token);
      if (changesetId == null) return false;

      final tags = _mapCategoryToTags(umkm['jenis_dagangan'] ?? '');
      String tagXml = "";
      tags.forEach((k, v) {
        tagXml += '<tag k="$k" v="$v"/>\n';
      });
      
      // Tambah tag alamat resmi wilayah
      tagXml += '<tag k="addr:city" v="Bogor"/>\n';
      tagXml += '<tag k="addr:subdistrict" v="Ciampea"/>\n';
      tagXml += '<tag k="addr:full" v="Kp. Sinagar RT 003 RW 006"/>\n';

      // Escape data input user agar XML tidak pecah
      final String safeName = _escapeXml(umkm['nama_bisnis'] ?? 'Toko Warga');
      final String safeDesc = _escapeXml(umkm['deskripsi'] ?? 'UMKM Terverifikasi');
      final String safeWa = _escapeXml(umkm['nomor_wa'] ?? '');

      final nodeXml = """
      <osm>
        <node changeset="$changesetId" lat="${umkm['latitude']}" lon="${umkm['longitude']}">
          <tag k="name" v="$safeName"/>
          <tag k="description" v="$safeDesc"/>
          <tag k="phone" v="$safeWa"/>
          $tagXml
        </node>
      </osm>
      """;

      final response = await http.put(
        Uri.parse('$_baseUrl/node/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'text/xml',
        },
        body: nodeXml,
      );

      // Pastikan changeset ditutup apapun hasilnya
      await http.put(
        Uri.parse('$_baseUrl/changeset/$changesetId/close'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('OSM Push Error: $e');
      return false;
    }
  }
}
