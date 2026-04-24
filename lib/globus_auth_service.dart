import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/// Globus Auth Service
class GlobusAuthService {
  static const GRASSROOTS_PAGE_URL = "https://grassroots.tools/private/redirect.html";
  static const String GRASSROOTS_REDIRECT_URL = "https://grassroots.tools/private/redirect_uri";
  static const String USER_INFO_URL = "https://grassroots.tools/dev/grassroots/private/backend/operation/get_all_services";
  static const bool DEBUG = true;

  static const _secureStorage = FlutterSecureStorage();


  static Future<String?> getEmail() async {
    final email = await _secureStorage.read(key: 'GLOBUS_EMAIL');
    return email?? email;
  }

  static String capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  static Future<bool> isCredentialExist() async {
    final email = await _secureStorage.read(key: 'GLOBUS_EMAIL');
    final cookie = await _secureStorage.read(key: 'SESSION_COOKIE');
    //return email != null && cookie != null;
    return cookie != null;
  }

}
