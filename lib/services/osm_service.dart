import 'dart:convert';
import 'package:http/http.dart' as http;

class OsmService {
  static const double sinagarLat = -6.579545;
  static const double sinagarLng = 106.7162769;

  Future<List<Map<String, dynamic>>> fetchNearbyUmkm() async {
    // JURUS LOKAL: Radius 1500 meter (1.5 KM) agar lebih akurat dan relevan bagi warga
    const query = """
    [out:json][timeout:30];
    (
      node["shop"](around:1500, $sinagarLat, $sinagarLng);
      way["shop"](around:1500, $sinagarLat, $sinagarLng);
      node["amenity"~"restaurant|cafe|fast_food|laundry|pharmacy|atm|bank"](around:1500, $sinagarLat, $sinagarLng);
      way["amenity"~"restaurant|cafe|fast_food|laundry|pharmacy|atm|bank"](around:1500, $sinagarLat, $sinagarLng);
    );
    out center;
    """;

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'User-Agent': 'SadaraWargaApp/1.0.0'},
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];

        return elements.map((e) {
          final tags = e['tags'] as Map<String, dynamic>;
          double lat = e['lat'] ?? e['center']?['lat'] ?? 0.0;
          double lon = e['lon'] ?? e['center']?['lon'] ?? 0.0;
          
          return {
            'id': 'osm_${e['id']}',
            'source': 'osm',
            'nama_bisnis': tags['name'] ?? 'Toko Tanpa Nama',
            'jenis_dagangan': tags['shop'] ?? tags['amenity'] ?? 'Usaha Lainnya',
            'latitude': lat,
            'longitude': lon,
            'deskripsi': 'Data publik OpenStreetMap',
            'nomor_wa': tags['phone'] ?? tags['contact:phone'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
