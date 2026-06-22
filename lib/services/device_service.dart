import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceKey = 'sadara_device_uuid';

  /// Mendapatkan ID Unik Perangkat yang konsisten untuk instalasi aplikasi ini.
  /// Kita simpan di SharedPreferences agar tidak berubah-ubah.
  Future<String> getUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceKey);

    if (deviceId == null) {
      // Jika belum ada, kita buat baru
      final deviceInfo = DeviceInfoPlugin();
      String rawId = '';

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          // Kita gabungkan beberapa identitas hardware agar lebih unik
          rawId = '${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          rawId = iosInfo.identifierForVendor ?? const Uuid().v4();
        }
      } catch (e) {
        rawId = const Uuid().v4();
      }

      // Kita bungkus lagi dengan UUID agar formatnya standar dan anonim
      deviceId = const Uuid().v5(Uuid.NAMESPACE_URL, rawId);
      await prefs.setString(_deviceKey, deviceId);
    }

    return deviceId;
  }
}
