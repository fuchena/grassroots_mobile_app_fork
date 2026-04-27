import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:http/http.dart' as http;

class GrassrootsRequest {
  // Server names for public, private and queen services. Currently using BETA SERVER
/*
  static const Map<String, String> _serverUrls = {
    'public': 'https://grassroots.tools/grassroots/public_backend',    
    'private': 'https://grassroots.tools/grassroots/private_backend',
    'queen_bee_backend': 'https://grassroots.tools/grassroots/queen_bee_backend'
  };
*/

  // User name and password for requests to queen services.
  static const String _username = 'doc';
  static const String _password = '123_REPLACE_';
  static const _secureStorage = FlutterSecureStorage();


  static Future<Map<String, dynamic>> sendRequest(String requestString, String serverKey,) async {
    String? url;

    if (serverKey == "public") {
      url = GrassrootsConfig.GetPublicBackendURL ();
    } else if (serverKey == "private") {
      url = GrassrootsConfig.GetPrivateBackendURL ();
    } else if (serverKey == "queen_bee") {
      url = GrassrootsConfig.GetAdminBackendURL ();
    }

    if (url == null) {
      throw Exception('Server key "$serverKey" does not correspond to a known server.');
    }

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print (">>> Calling Grassroots Server at $url");
    }

    //String? userEmail = await GlobusAuthService.getEmail();
    final cookie = await _secureStorage.read(key: 'SESSION_COOKIE');
    //final sub = await _secureStorage.read(key: 'SUB');
    //print('mod_cookie: $cookie');

    //String basicAuth = 'Basic ' + base64Encode(utf8.encode("username:$accessToken"));


    // Creating a Map for headers
     final headers = {
      //"Authorization": "Bearer $accessToken",
       'Accept': 'application/json',
       'Cookie': 'mod_auth_openidc_session=$cookie'
    };

    // If the server key is for the queen_bee_backend, add the Authorization header
    if (serverKey == 'queen_bee_backend') {
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
      headers['Authorization'] = basicAuth;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: requestString,
    );

    print('Request String: $requestString');
    // The rest of your method remains unchanged
    if (response.statusCode == 200) {

      if (GrassrootsConfig.log_level >= LOG_FINER) {
        //print ("REQUEST: ${response.body}");
        print ("RESPONSE BODY: ${response.body}");
      }

      var data = json.decode(response.body);
      if ((data['results'] as List).isEmpty) {
        throw Exception("EmptyResults");
      }
      return data;
    } else {
      throw Exception('Failed to load data from the server with status: ${response.statusCode}');
    }
  }

  static String getRequestString(String qrCode) {
    //return '{"services": [{"so:name": "Search Field Trials","start_service": true,"parameter_set": {"level": "advanced","parameters": [{"param": "ST Id","current_value": "$qrCode"}, {"param": "Get all Plots for Study","current_value": true}, {"param": "ST Search Studies","current_value": true}]}}]}';
    return '{"services": [{"so:name": "Search Field Trials","start_service": true,"parameter_set": {"level": "advanced","parameters": [{"param": "Plot ID","current_value": "$qrCode","group": "Plots and Racks"}]}}]}';
  }
}
