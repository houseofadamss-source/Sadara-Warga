import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OsmOAuth2Client extends OAuth2Client {
  OsmOAuth2Client({required super.redirectUri, required super.customUriScheme})
      : super(
          authorizeUrl: 'https://www.openstreetmap.org/oauth2/authorize',
          tokenUrl: 'https://www.openstreetmap.org/oauth2/token',
        );
}

class OsmAuthService {
  final _storage = const FlutterSecureStorage();
  final String clientId = 'IaaDKU7rJlRdTek9C7A52e1R9-6mO1gAvPeWCgxccOY';
  final String redirectUri = 'com.sadarawarga.app://oauth2redirect';
  final String customUriScheme = 'com.sadarawarga.app';

  Future<String?> getValidToken() async {
    String? token = await _storage.read(key: 'osm_access_token');
    // Simple check, real implementation might need to handle refresh tokens
    return token;
  }

  Future<String?> login() async {
    OsmOAuth2Client client = OsmOAuth2Client(
      redirectUri: redirectUri,
      customUriScheme: customUriScheme,
    );

    try {
      AccessTokenResponse tknResp = await client.getTokenWithAuthCodeFlow(
        clientId: clientId,
        scopes: ['write_api'],
      );

      if (tknResp.isValid()) {
        await _storage.write(key: 'osm_access_token', value: tknResp.accessToken);
        return tknResp.accessToken;
      }
    } catch (e) {
      print('OSM Login Error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'osm_access_token');
  }
}
