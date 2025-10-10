import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';

/// Config (move to env/secure store in real app)
class GlobusConfig {
  static const clientId = '4ca0e2cf-5369-4396-b1ae-0a23015abe77';
  static const clientSecret = 'sUX89ts5kT4WPG8CNF7BrYIl2S/QKRVD9yf81xE3/10=';
  static const redirectUri =
      'https://grassroots.tools/dev/service/orcid/login2';
  static const authBase = 'auth.globus.org';
}

/// Simple Globus Auth Service
class GlobusAuthService {
  static final _http = http.Client();
  static final _secureStorage = const FlutterSecureStorage();
  //gets token (IdToken, Access token, refresh token etc) based on authorization code
  static Future<Map<String, dynamic>?> exchangeCodeForToken(String code) async {
    final basicAuth = 'Basic ${base64Encode(
      utf8.encode('${GlobusConfig.clientId}:${GlobusConfig.clientSecret}'),
    )}';

    final response = await _http.post(
      Uri.https(GlobusConfig.authBase, '/v2/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': basicAuth,
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': GlobusConfig.redirectUri,
      },
    );

    if (response.statusCode == 200) {
      print('TokenResponse ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  //userinfo endpoint
  static Future<String?> fetchUserEmail(String accessToken) async {
    final response = await _http.get(
      Uri.https(GlobusConfig.authBase, '/v2/oauth2/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      final userInfo = jsonDecode(response.body);
      print('UserInfo: $userInfo');
      return userInfo['email'] as String?;
    }
    return null;
  }

  static void logout(BuildContext context) async {
    await _secureStorage.delete(key: 'GLOBUS_EMAIL');
    await _secureStorage.delete(key: 'ID_TOKEN');
    await WebViewCookieManager().clearCookies();
    // Navigate back to login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  static Future<String> getUserName() async {
    String? name = await _secureStorage.read(key: 'GLOBUS_EMAIL');
    if (name == null) {
      name = '...';
    }
    return name;
  }

  static String capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  static Future<bool> isCredentialExist() async {
    final email = await _secureStorage.read(key: 'GLOBUS_EMAIL');
    final idToken = await _secureStorage.read(key: 'ID_TOKEN');
    return email != null && idToken != null;
  }
}
