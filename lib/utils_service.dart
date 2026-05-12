import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/// Utility Service class
class UtilsService {
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

  static String? validateStringField(String? value) {
    String? res;

    print("Value \"$value\"");

    if ((value == null) || (value.trim().isEmpty)) {
      res = "This is required";
    }

    return res;
  }

  static String? validateNumberField(String? value) {
    if (value != null) {
      int? c = int.tryParse(value);

      if (c != null) {
        if (c > 0) {
          return null;
        } else {
          return "Value must be a number greater than 0";
        }
      } else {
        return "Value must be a number";
      }
    } else {
      return "This is required";
    }
  }
  static String? validateDropdownField(String? value) {
    if ((value == null) || value.trim().isEmpty) {
      return "This is required";
    }

    return null;
  }

}
