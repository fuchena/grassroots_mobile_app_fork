import 'dart:io';
import 'package:global_configuration/global_configuration.dart';
import 'package:grassroots_field_trials/caching.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:http/http.dart' as http;
//import 'package:flutter/material.dart';
//import 'dart:typed_data';
import 'dart:convert'; // For jsonDecode()
import 'package:intl/intl.dart';

class ApiRequests {
  static String latest_error = "";


  static Uri? GetPhotoReceiverEndpoint (final String url) {
    Uri? uri = null;
    final String? base_url = GrassrootsConfig.GetPhotoReceiverURL ();
    String s;

    if (base_url != null) {
      if (base_url.endsWith ("/")) {
        s = "${base_url}${url}";
      } else {
        s = "${base_url}/${url}";
      }

      uri = Uri.parse (s);

    }
    return uri;
  }

  static Future<bool> uploadImageDate (File image, String studyID, int plotNumber) async {
    bool success_flag = false;

    try {
      Uri? uri = GetPhotoReceiverEndpoint ("upload/");

      if (uri != null) {
        // Include the current date in the file name
        String date = DateFormat('yyyy_MM_dd').format(DateTime.now());
        String newFileName = 'photo_plot_${plotNumber.toString()}_${date}.jpg';

        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: newFileName,
        ));

        request.fields['subfolder'] = studyID;
        request.fields['plot_number'] =
            plotNumber.toString(); // Add plot_number to the request
        var response = await request.send();

        success_flag = response.statusCode == 201; // Return true if status code is 201
      }
    } catch (e) {
      // Return false in case of an error
    }

    return success_flag;
  }

  static Future<Map<String, dynamic>> retrievePhoto(String studyID, int plotNumber) async {
    Map<String, dynamic> res = {'status': 'not_found'};

    try {
      String subfolder = studyID;
      String photoName = 'photo_plot_${plotNumber.toString()}.jpg';
      Uri? uri = GetPhotoReceiverEndpoint ("retrieve_photo/$subfolder/$photoName");

      if (uri != null) {
        var response = await http.get(uri);

        if (response.statusCode == 200) {
          res = {'status': 'success', 'data': response.bodyBytes};
        } else {
        }
      }
    } catch (e) {
      print('Error: $e');
      res = {'status': 'error', 'message': 'Error: $e'};
    }

    return res;
  }

  static Future<Map<String, dynamic>> retrieveLastestPhoto(String studyID, int plotNumber) async {
    Map <String, dynamic> res = {'status': 'not_found'};

    try {
      // Updated API URL to match the new endpoint
      //print path used for the API
      Uri? uri = GetPhotoReceiverEndpoint ("retrieve_latest_photo/$studyID/$plotNumber/");

      if (uri != null) {
        var response = await http.get (uri);

        if (response.statusCode == 200) {
          // Parse the JSON response
          var jsonResponse = json.decode(response.body);

          // Check if the status is success and extract URL
          if (jsonResponse['status'] == 'success') {
            res = {
              'status': 'success',
              'url': jsonResponse['url'], // Extract and return the URL instead of bytes
            };
          }
        } else {
        }


      }

   } catch (e) {
      print('Error: $e');
      res = {'status': 'error', 'message': 'Error: $e'};
    }

    return res;
  }

  static Future<Map<String, Map<String, int?>>?> retrieveLimits(String studyID) async {
    try {
      String subfolder = studyID;
      Uri? uri = GetPhotoReceiverEndpoint ("retrieve_limits/$subfolder/");

      if (uri != null) {
        var response = await http.get(uri);

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          print('JSON Response: $jsonResponse');

          // Initialize a result map
          Map<String, Map<String, int?>> limits = {};

          // Iterate over the keys in the JSON response and store limits dynamically
          jsonResponse.forEach((traitKey, traitLimits) {
            if (traitLimits['min'] != null && traitLimits['max'] != null) {
              limits[traitKey] = {
                'min': traitLimits['min'],
                'max': traitLimits['max'],
              };
              print(
                  '-----Trait: $traitKey, Min: ${traitLimits['min']}, Max: ${traitLimits['max']}');
            }
          });

          return limits;
        } else {
          print('Failed to retrieve limits.json: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error retrieving limits.json: $e');
    }

    return null; // Return null or an empty map if no limits are found or there's an error
  }

  static Future<bool> updateLimits(String studyID, int newMin, int newMax, String traitKey) async {
    bool success_flag = false;
    String subfolder = studyID;
    Uri? uri = GetPhotoReceiverEndpoint ("update_limits/$subfolder/");

    if (uri != null) {
      try {
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            traitKey: {'min': newMin, 'max': newMax}
          }),
        );

        // Log the status code and response body for debugging
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        success_flag = response.statusCode == 200;
      } catch (e) {
        print('Error updating limits: $e');
      }
    }

    return success_flag;
  }

  static Future<List<String>?> fetchAllowedStudyIDs() async {
    List <String> ? ids = null;
    Uri? uri = GetPhotoReceiverEndpoint ("allowed_studies/");

    if (uri != null) {

      try {
        final response = await http.get (uri);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);

          List <String> allowed_studies = List<String>.from(jsonResponse['allowed_studies']);

          //IdsCache.cacheIds (allowed_studies);

          ids = allowed_studies;

        } else {
          print('Error fetching allowed study IDs: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching allowed study IDs: $e');
      }
    }

    return ids;
  }

  static Future<Map<String, String>> fetchHealthStatus() async {
    Map <String, String> res =  {
      'django': 'error',
      'mongo': 'error',
    };

    Uri? uri = GetPhotoReceiverEndpoint ("online_check/");
    if (uri != null) {
      try {
        final response = await http.get (uri);
        if (GrassrootsConfig.log_level >= LOG_INFO) {
          print ("called ${uri} got ${response.statusCode}");
        }

        if (response.statusCode == 200) {
          // Parse the JSON response and return it
          final jsonResponse = json.decode(response.body);

          res = {
            'django': jsonResponse['django'] ?? 'unknown',
            'mongo': jsonResponse['mongo'] ?? 'unknown',
          };

        } else {
          // Handle non-200 responses
          res = {
            'django': 'unreachable',
            'mongo': 'unknown',
          };
        }
      } catch (e) {
        latest_error = e.toString();
        // Handle errors like network issues
      }

    }

    return res;
  }


  static Future <bool> isServerHealthy () async {
    final Map <String, String> healthStatus = await fetchHealthStatus ();

    String djangoStatus = healthStatus['django'] ?? 'unknown';
    String mongoStatus = healthStatus['mongo'] ?? 'unknown';
    
    return ((djangoStatus == 'running') && (mongoStatus == 'available'));
  }
  
}
