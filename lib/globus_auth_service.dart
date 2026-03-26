import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'global_variable.dart';
import 'login_page.dart';

/// Config
class GlobusConfig {
  static final Map<String,dynamic>? globus = GrassrootsConfig.GetGlobusConfig();
  static const _secureStorage =  FlutterSecureStorage();

  static final update = globus?["update"] ;
  static final clientId = globus?["clientId"];
  static final clientSecret = globus?["clientSecret"];
  static final authBase = globus?["authBase"];
  static final redirectUri = globus?["redirectUri"];

  static Future<void> globusUpdateConfig() async {
     if (kDebugMode ) {
       await _secureStorage.write(key: 'CLIENT_SECRET', value: clientSecret);
    }
  }
}

/// Globus Auth Service
class GlobusAuthService {
  static final _http = http.Client();
  static const _secureStorage = FlutterSecureStorage();


  static Future<Uri> buildAuthorizationUrl() async {
    //authorization endpoint
    final authUrl = Uri.https(GlobusConfig.authBase, '/v2/oauth2/authorize', {
      'response_type': 'code',
      'client_id': GlobusConfig.clientId,
      'redirect_uri': GlobusConfig.redirectUri,
      'scope': 'profile openid email offline_access',
      'access_type': 'offline',
      'prompt': 'login',
    });

    return authUrl;

  }


  //gets token (IdToken, Access token, refresh token etc) based on authorization code
  static Future<Map<String, dynamic>?> exchangeCodeForToken(String code) async {
    //GlobusConfig.globusUpdateConfig();
    final clientSecret = await _secureStorage.read(key: 'CLIENT_SECRET');
    final basicAuth = 'Basic ${base64Encode(
      utf8.encode('${GlobusConfig.clientId}:${clientSecret}'),
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

    if (response.statusCode != 200) {
      throw Exception(
          'Backend token exchange failed: ${response.statusCode} ${response.body}');
    }
    //print('TokenResponse ${response.body}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  //userinfo endpoint
  static Future<Map<String, dynamic>?> fetchUserInfo(String accessToken) async {
    final response = await _http.get(
      Uri.https(GlobusConfig.authBase, '/v2/oauth2/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Backend fetch user info failed: ${response.statusCode} ${response.body}');
    }
    //final userInfo = jsonDecode(response.body);
    //print('UserInfo: $userInfo');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }


  static void logout(BuildContext context) async {

  }

  static Future<void> clearStoredTokens() async {
    await _secureStorage.delete(key: "ACCESS_TOKEN");
    await _secureStorage.delete(key: 'GLOBUS_EMAIL');
    await _secureStorage.delete(key: 'SUB');
    await _secureStorage.delete(key: 'USER_NAME');
  }

  static Future<String?> getFirstName() async {
    final email = await getEmail();
    return email != null ? capitalize(email) : null;
  }

  static Future<String?> getEmail() async {
    final email = await _secureStorage.read(key: 'GLOBUS_EMAIL');
    return email != null ? email : null;
  }

  static String capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  static Future<bool> isCredentialExist() async {
    final email = await _secureStorage.read(key: 'GLOBUS_EMAIL');
    final accessToken = await _secureStorage.read(key: 'ACCESS_TOKEN');
    //return email != null && accessToken != null;
    return accessToken != null;
  }

//refresh token function here
}
