import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password, String deviceId);
  Future<void> register({
    required String nik,
    required String nama,
    required String email,
    required String hp,
    required String alamat,
    required String password,
    required String fotoKkUrl,
    required String deviceId,
  });
  Future<UserModel> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> login(String email, String password, String deviceId) async {
    // 1. Auth Login
    final response = await client.auth.signInWithPassword(email: email, password: password);
    if (response.user == null) throw Exception('Login gagal');

    // 2. Fetch Profile
    final userData = await client.from('users').select().eq('id', response.user!.id).maybeSingle();
    if (userData == null) throw Exception('Profil tidak ditemukan');

    // 3. Logic Gembok HP di DataSource (Atau bisa di UseCase, tapi di sini lebih praktis)
    final registeredDeviceId = userData['device_id'];
    if (registeredDeviceId == null) {
      await client.from('users').update({'device_id': deviceId}).eq('id', response.user!.id);
    } else if (registeredDeviceId != deviceId) {
      await client.auth.signOut();
      throw Exception('DEVICE_LOCKED'); // Kode khusus biar failure tau
    }

    return UserModel.fromJson(userData);
  }

  @override
  Future<void> register({
    required String nik,
    required String nama,
    required String email,
    required String hp,
    required String alamat,
    required String password,
    required String fotoKkUrl,
    required String deviceId,
  }) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nik': nik,
        'nama_lengkap': nama,
        'nomor_hp': hp,
        'alamat': alamat,
        'foto_kk': fotoKkUrl,
        'device_id': deviceId,
      },
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Sesi berakhir');
    
    final data = await client.from('users').select().eq('id', user.id).maybeSingle();
    if (data == null) throw Exception('User data not found');
    
    return UserModel.fromJson(data);
  }

  @override
  Future<void> logout() async {
    await client.auth.signOut();
  }
}
