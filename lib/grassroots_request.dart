import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:http/http.dart' as http;

import 'package:global_configuration/global_configuration.dart';

import 'globus_auth_service.dart';


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
  static final _secureStorage = const FlutterSecureStorage();


  static Future<Map<String, dynamic>> sendRequest(String requestString, String serverKey,) async {
    String? url = null;

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
      print (">>> Calling Grassroots Server at ${url}");
    }

    String? userEmail = await GlobusAuthService.getEmail();
    final accessToken = await _secureStorage.read(key: 'ACCESS_TOKEN');
    final sub = await _secureStorage.read(key: 'SUB');
    print('accessToken: $accessToken');


    final accessTokenObj = {"access_token": accessToken};

    //final mod_auth_openidc_session  = "eyJhbGciOiAiZGlyIiwgImVuYyI6ICJBMjU2R0NNIn0..ouANzbHD_dauKf8Z.aBGlsm2emPhfsB6jeRnptYEgoLN-S8IX6gZv9D_tpRGhf_H5qTm1JHI-W0cbwQ3N5G7v36-h3_OHEWNyJNThBN1nBT3wAfLgnrzlhYlknk4XoaZahKE3lbYIZkxderiWCrpHvflBLCsLvHyp9jXDDKvz3kS3QyZq-4iRZroudw3MFnSTySPLNwwcvyWGZkCwle5bm4mNqE4iwU0BJcrELk9ixNcQWi0gpXWm_cZOsiC7_WN6ULZ-ETt_YQejmZegBxdr5SGq2gFyG720bfwMQD0q0ub5SBiurWecbPF7Yi0LIgLqhLuvy28mnu9Igz-E15UqgzYR_cRl3dZBFyCVF5-DLatkOjMs02qoCNi7I2TCpxELm9yjz78ulYFnHMCvQUMGxKQLuGD_GPA-d2ARK4SeWYRddqPmX1NpPQ5Ehk-5o_WZ36O5iERdUR6loqwkO_SDZt5QuWdVrnGBM3WP9TJJPIiXeDllnAoAKjS7780zRQ-tMnAF6CfLQgmA42A3Q8X-WKZU8MTkNxhjnoW2O45PHTd95aq8rm9E6c2lZDsAlVlipardwRmHcLM5lK5TPELkgFUA08LpAK8DjNNLOZ0pnQkEhO-kw4ys4-i6OKiP42cDoQsqJ2jrsw-Ph6J6iuAR_GA2CmjPlw8X60hN5MhwI744P3U503kry2vAqBMoHhWfkQk4rp9LcOMsAatxhRuVN0BO9X9ZKWeLeKdbOzDlbnTFRaK4NgyksJpO3SCbrYGRap3sYTY-8iA.WkqORYQvB8lE6LZ7XruHHA; _ga_9RQFH7EWX4=GS2.1.s1763479661\$o68\$g0\$t1763479661\$j60\$l0\$h0; TS01e5ba45=01485ef4df465af4f9ed85de129551010cbfbf7a86e99107bf888781a14878299b3f91e46a691cba3236f2c9421f41389a666ef1a9a3186f37c0d4d0143920ee4e72f46865e7c3d68cc362aeec054ee8944f74cfd49ca04a7bed629ef4bf51dadec5098d0d0ddbec9f8b5b8e24b371a591cd154cd4a33caf45325bf6d9252f060e454a8bbf5c27f87cdd1981d62ed7097a1bf4d067e59c6c642189f56de2242b7112e53333fce72ce5596cb5a53e2c5e807768402bf2ac09ae6902f5539ac9087626cc8f80";

    String basicAuth = 'Basic ' + base64Encode(utf8.encode("username:$accessToken"));


    // Creating a Map for headers
    /*final headers = {
      "Authorization": "Bearer $accessToken",
      "Content-Type": "application/json",
    };
*/

    // Creating a Map for headers
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };


    // If the server key is for the queen_bee_backend, add the Authorization header
    if (serverKey == 'queen_bee_backend') {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('$_username:$_password'));
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
