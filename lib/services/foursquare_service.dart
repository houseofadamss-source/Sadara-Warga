import 'dart:convert';
import 'package:http/http.dart' as http;

class FoursquareService {
  final String apiKey = 'SU2M2JXNIARRFKZJFHAWWNOIML2QGYPOCOKW5VGP40A3VD2X';
  static const double sinagarLat = -6.579545;
  static const double sinagarLng = 106.7162769;

  Future<List<Map<String, dynamic>>> fetchNearbyPlaces() async {
    // JURUS SAPU BERSIH: Hapus kategori sempit, tambah radius ke 5km, minta field spesifik
    final String url = 'https://api.foursquare.com/v3/places/search?ll=$sinagarLat,$sinagarLng&radius=5000&limit=30&fields=fsq_id,name,categories,geocodes,location,distance';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        if (results.isEmpty) {
          print('Foursquare: Tidak ada data di radius ini.');
        }

        return results.map((e) {
          final categories = e['categories'] as List;
          String catName = 'Bisnis Lokal';
          if (categories.isNotEmpty) {
            catName = categories[0]['name'];
          }

          double lat = 0.0;
          double lon = 0.0;
          if (e['geocodes'] != null && e['geocodes']['main'] != null) {
            lat = e['geocodes']['main']['latitude'];
            lon = e['geocodes']['main']['longitude'];
          }

          return {
            'id': 'fsq_${e['fsq_id']}',
            'source': 'foursquare',
            'nama_bisnis': e['name'] ?? 'Toko Tanpa Nama',
            'jenis_dagangan': catName,
            'latitude': lat,
            'longitude': lon,
            'deskripsi': e['location']?['formatted_address'] ?? 'Alamat tidak tersedia',
            'distance': e['distance'] ?? 0,
          };
        }).toList();
      } else {
        print('Foursquare Error Code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
      return [];
    } catch (e) {
      print('Foursquare Exception: $e');
      return [];
    }
  }
}
