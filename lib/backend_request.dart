// qr_code_service.dart
//import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:grassroots_field_trials/caching.dart';
import 'package:grassroots_field_trials/measured_variables.dart';

import 'grassroots_request.dart';
import 'dart:convert';
import 'global_variable.dart';

class backendRequests {
  static final String SYNCED = "synced";
  static final String PENDING = "pending";


  //fetch all studies from Grassroots. Used when loading grassroot_studies.dart
  static Future<List<Map<String, String>>> fetchAllStudies () async {
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Search Field Trials",
          "start_service": true,
          "parameter_set": {
            "level": "advanced",
            "parameters": [
              {"param": "ST Search Studies", "current_value": true, "group": "Studies"},
              {
                "param": "The level of data to get for matching Studies",
                "current_value": "Names and Ids only",
                "group": "Studies"
              }
            ]
          }
        }
      ]
    });

    try {
      var response = await GrassrootsRequest.sendRequest(requestString, 'public');
      List<Map<String, String>> studies = response['results'][0]['results'].map<Map<String, String>>((study) {
        //String name = study['title'] as String? ?? 'Unknown Study';It is
        String name = study['data']['so:name'] as String? ?? 'Unknown Study';
        String id = study['data']['_id']['\$oid'] as String? ?? 'Unknown ID';
        return {'name': name, 'id': id};
      }).toList();

      // Sort studies alphabetically by name
      //studies.sort((a, b) => a['name']!.compareTo(b['name']!));

      IdNamesCache.cache (studies, CACHE_STUDIES);
      //print("ResponseStudies $studies");
      return studies;
    } catch (e) {
      print('Error fetching studies: $e');
      // Optionally, handle the error in a specific way or rethrow it
      throw e;
    }
  }

 //fetch all Trials from Grassroots. Used when loading grassroot_studies.dart
  static Future <List <Map <String, String>>> fetchAllTrials () async {
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Search Field Trials",
          "start_service": true,
          "parameter_set": {
            "level": "advanced",
            "parameters": [
              {"param": "FT Search", "current_value": true, "group": "Field Trials"}
            ]
          }
        }
      ]
    });

    try {
      var response = await GrassrootsRequest.sendRequest(requestString, 'public');

      List<Map<String, String>> trials = response['results'][0]['results'].map<Map<String, String>>((trial) {
        //String name = study['title'] as String? ?? 'Unknown Study';
        String name = trial['data']['so:name'] as String? ?? 'Unknown Trial';
        String id = trial['data']['_id']['\$oid'] as String? ?? 'Unknown ID';

        return {'name': name, 'id': id};
      }).toList();

      // Sort trials alphabetically by name
      trials.sort((a, b) => a['name']!.compareTo(b['name']!));

      IdNamesCache.cache (trials, CACHE_TRIALS);

      return trials;
    } catch (e) {
      print('Error fetching trials: $e');
      // Optionally, handle the error in a specific way or rethrow it
      throw e;
    }
  }


 //fetch all Locations from Grassroots. Used when loading grassroot_studies.dart
  static Future <List <Map <String, String>>> fetchAllLocations () async {
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Search Field Trials",
          "start_service": true,
          "parameter_set": {
            "level": "advanced",
            "parameters": [{
              "param": "Get all Locations",
              "current_value": true,
              "group": "Location"
            }]
          }
        }
      ]
    });

    try {
      var response = await GrassrootsRequest.sendRequest(requestString, 'public');

      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print ("locations: ${response}");
      }

      List<Map<String, String>> locations = response['results'][0]['results'].map<Map<String, String>>((location) {
        //String name = study['title'] as String? ?? 'Unknown Study';
        String name = location['data']['name'] as String? ?? 'Unknown Location';
        String id = location['data']['_id']['\$oid'] as String? ?? 'Unknown ID';

        if (GrassrootsConfig.log_level >= LOG_FINEST) {
          print ("Adding location ${name}");
        }

        return {'name': name, 'id': id};
      }).toList();
      print ("num locations ${locations.length}");

      // Sort studies alphabetically by name
      locations.sort((a, b) => a['name']!.compareTo(b['name']!));

      IdNamesCache.cache (locations, CACHE_LOCATIONS);

      return locations;
    } catch (e) {
      print('Error fetching Locations: $e');
      // Optionally, handle the error in a specific way or rethrow it
      throw e;
    }
  }

  //fetch single study from Grassroots. Used after a study is selected in grassroot_studies.dart
  static Future<Map<String, dynamic>> fetchSingleStudy(String studyId) async {
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Search Field Trials",
          "start_service": true,
          "parameter_set": {
            "level": "advanced",
            "parameters": [
              {"param": "ST Id", "current_value": studyId},
              //{"param": "Get all Plots for Study", "current_value": true},
              {"param": "The level of data to get for matching Studies", "current_value": "Full"},
              {"param": "ST Search Studies", "current_value": true}
            ]
          }
        }
      ]
    });
    return await GrassrootsRequest.sendRequest(requestString, 'public');
  }

  ////////// request for submitting observation used in new_observation.dart //////////
  static String GetSubmitObservationRequest({
    required String studyId,
    required String plotId,
    required String? selectedTrait,
    required String measurement,
    required String dateString,
    String? accession,
    String? note,
  }) {
// List of allowed study IDs
  //  const allowedStudyIDs = [
  //    '64f1e4e77c486e019b4e3017',
  //    '63bfce1a86ff5b59175e1d66',
  //    '65a532e1536b7214e714a97f', //Glasshouse test study
  //  ];

    // Check if the studyID is in the list of allowed IDs
    if (!GrassrootsConfig.IsStudyEditable (studyId)) {
      // If not allowed, handle accordingly. For example:
      print('Modification not allowed for this study.');
      return '{}'; // Return a dummy JSON string or handle as needed
    }

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print ("studyId ${studyId}");
      print ("detectedQRCode ${plotId}");
      print ("selectedTrait ${selectedTrait}");
      print ("measurement ${measurement}");
      print ("dateString ${dateString}");
      print ("accession ${accession}");
      print ("note ${note}");
    }

    List <Map <String, Object>> params_array = [
      {"param": "RO Id", "current_value": plotId, "group": "Plot"},
      {"param": "RO Append Observations", "current_value": true, "group": "Plot"},
      {
        "param": "RO Measured Variable Name",
        "current_value": [selectedTrait],
        "group": "Phenotypes"
      },
      {
        "param": "RO Phenotype Raw Value",
        "current_value": [measurement],
        "group": "Phenotypes"
      },
      {
        "param": "RO Phenotype Corrected Value",
        "current_value": [null],
        "group": "Phenotypes"
      },
      {
        "param": "RO Phenotype Start Date",
        "current_value": [dateString],
        "group": "Phenotypes"
      },
      {
        "param": "RO Phenotype End Date",
        "current_value": [null],
        "group": "Phenotypes"
      },
      {
        "param": "RO Observation Notes",
        "current_value": note != null ? [note] : [null],
        "group": "Phenotypes"
      }
    ];

    if ((accession != null) && (accession.isNotEmpty)) {
      params_array.add ({
        "param": "RO Accession",
        "current_value": accession,
        "group": "Plot"
      });
    }

    final requestMap = {
      "services": [
        {
          "so:name": "Edit Field Trial Rack",
          "start_service": true,
          "parameter_set": {
            "level": "simple",
            "parameters": params_array
          }
        }
      ]
    };

    // Convert map to a JSON string
    String req = jsonEncode (requestMap);
    
    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print ("Obs req: ${req}");
    }

    return req;
  }

  ////////// request for submitting plot_accession used in new_observation.dart //////////
  static String GetSubmitAccessionRequest({
    required String studyId,
    required String plotId,
    required String accession,
  }) {
    String req = "{}";

    // Check if the studyID is in the list of allowed IDs
    if (GrassrootsConfig.IsStudyEditable (studyId)) {
      if (accession.isNotEmpty) {
        if (GrassrootsConfig.log_level >= LOG_FINE) {
          print ("studyId ${studyId}");
          print ("detectedQRCode ${plotId}");
          print ("accession ${accession}");
        }

        List <Map <String, Object>> params_array = [
          {"param": "RO Id", "current_value": plotId, "group": "Plot"},
        ];

        if (accession.isNotEmpty) {
          params_array.add ({
            "param": "RO Accession",
            "current_value": accession,
            "group": "Plot"
          });
        }

        final requestMap = {
          "services": [
            {
              "so:name": "Edit Field Trial Rack",
              "start_service": true,
              "parameter_set": {
                "level": "simple",
                "parameters": params_array
              }
            }
          ]
        };

        // Convert map to a JSON string
        req = jsonEncode (requestMap);

        if (GrassrootsConfig.log_level >= LOG_FINE) {
          print ("Obs req: ${req}");
        }

      } else {
        print ('No accession value specified.');
      }

    } else {
      // If not allowed, handle accordingly. For example:
      print('Modification not allowed for this study.');
    }

    return req;
  }




//-- request for clearing cache after submitting observation (Used in new_observation.dart).
  static String clearCacheRequest(String studyID) {
    final Map<String, dynamic> request = {
      "services": [
        {
          "start_service": true,
          "so:alternateName": "field_trial-manage_study",
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {"param": "ST Id", "current_value": studyID},
              {"param": "SM uuid", "current_value": studyID},
              {"param": "SM clear cached study", "current_value": true},
              {"param": "SM indexer", "current_value": "<NONE>"},
              {"param": "SM Delete study", "current_value": false},
              {"param": "SM Remove Study Plots", "current_value": false},
              {"param": "SM Generate FD Packages", "current_value": false},
              {"param": "SM Generate Handbook", "current_value": false},
              {"param": "SM Generate Phenotypes", "current_value": false},
            ]
          }
        }
      ]
    };

    return json.encode(request);
  }

  static Future <List <MeasuredVariable>>  searchMeasuredVariables (String? query) async {
    if (query != null) {
      /* Enable pattern matching */
      query = query + "*";
    }

    final String request = jsonEncode({
      "services": [
        {
          "start_service": true,
          "so:name": "Search Grassroots",
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {
                "param": "SS Keyword Search",
                "current_value": query
              },
              {
                "param": "SS Facet",
                "current_value": "Measured Variable"
              }
            ]
          }
        }
      ]
    });
  

    try {
      Map <String, dynamic> response = await GrassrootsRequest.sendRequest (request, 'public');
      
      List <dynamic> results_data = response ['results'][0]['results'];
      //print ("RESPONSE RESULT: ${results_data}");


      List <MeasuredVariable> measured_variables = []; //results_data.map<Map <String, dynamic>> ((mv) {

      print ("num hits ${results_data.length}");

      results_data.forEach ((entry) {
       // print ("entry: ${entry}");
              
        MeasuredVariable mv = MeasuredVariable.fromJson (entry ["data"]);

      //  print ("mv: ${mv.variable_name}");

        measured_variables.add (mv);
      });

//        print ("mv: ${mv}");
//        //return MeasuredVariable.fromJson (mv);
//        return MeasuredVariable("id", "unit_name", "trait_name", "trait_descrption", "measurement_name", "measurement_description", "variable_name");
//      }).toList ();
      

      // Sort studies alphabetically by name
      //measured_variables.sort((a, b) => a['name']!.compareTo(b['name']!));

      //IdNamesCache.cache (measured_variables, CACHE_MEASURED_VARIABLES);

      print ("RETURNING: ${measured_variables.length} Measured Variables");

      return measured_variables;
    } catch (e) {
      print('Error fetching measured variables: $e');
      // Optionally, handle the error in a specific way or rethrow it
      throw e;
    }    
  }

// This will process the capture and return the detected QR code's raw value or null
  //String? processDetectedQR(BarcodeCapture capture) {
  //  final List<Barcode> barcodes = capture.barcodes;
  //  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
  //    return barcodes.first.rawValue!;
  //  }
  //  return null;
  //}

  // Fetch data based on the detected QR code
  //Future<Map<String, dynamic>> fetchDataFromQR(String qrRawValue) async {
  //  try {
  //    final Map<String, dynamic> responseData =
  //        await GrassrootsRequest.sendRequest(GrassrootsRequest.getRequestString(qrRawValue), 'public');

  // Additional logic ...

  ///    return responseData; // Return the processed or raw response data
  ///  } catch (e) {
  //    print(e.toString());
  //    // Handle errors and return an appropriate response or throw an error
  //    return {"error": e.toString()};
  //  }
  //}

  //ParsedData parseResponseData(Map<String, dynamic> responseData) {
  //  ParsedData parsedData = ParsedData();

  //  parsedData.statusText = responseData['results'][0]['status_text'];

  //  if (parsedData.statusText == "Succeeded" || parsedData.statusText == "Partially succeeded") {
  //    parsedData.studyIndex = responseData['results'][0]['results'][0]['data']['study_index'];
  //    parsedData.accession = responseData['results'][0]['results'][0]['data']['material']['accession'];
  //    parsedData.observationsCount = (responseData['results'][0]['results'][0]['data']['observations'] as List?)?.length ?? 0;

  //   if (responseData['results'][0]['results'][0]['data'].containsKey('observations')) {
  //     parsedData.studyName = responseData['results'][0]['results'][0]['data']['study']['so:name'];
  //     parsedData.studyID = responseData['results'][0]['results'][0]['data']['study']['_id']['\$oid'];
  //     var observations = responseData['results'][0]['results'][0]['data']['observations'];
  //     parsedData.observations = observations; // Store observations to parsedData
  //     for (var observation in observations) {
  //       String? variable = observation['phenotype']['variable'];
  //       if (variable != null && !parsedData.parsedPhenotypeNames.contains(variable)) {
  //         parsedData.parsedPhenotypeNames.add(variable);
  //       }
  //     }

  //     var phenotypesInfo = responseData['results'][0]['results'][0]['data']['phenotypes'];
  //     for (var phenotypeName in parsedData.parsedPhenotypeNames) {
  //       var phenotypeData = phenotypesInfo[phenotypeName];
  //       if (phenotypeData != null) {
  //         String? traitName = phenotypeData['definition']['trait']['so:name'];
  //         String? unitName = phenotypeData['definition']['unit']['so:name'];
  //         if (traitName != null) {
  //           parsedData.traits.add(traitName);
  //         }
  //         parsedData.units.add(unitName ?? 'No Unit');
  //       }
  //     }
  //print("phenotypeNames: ${parsedData.parsedPhenotypeNames}");
  //   }
  // Additional logic to extract all phenotypes names from the 'phenotypes' key
  //   var phenotypesInfo = responseData['results'][0]['results'][0]['data']['phenotypes'];
  //   for (var phenotypeKey in phenotypesInfo.keys) {
  //     String? phenotypeName = phenotypesInfo[phenotypeKey]['definition']['variable']['so:name'];
  //     String? traitName = phenotypesInfo[phenotypeKey]['definition']['trait']['so:name'];

  //    if (phenotypeName != null && !parsedData.allPhenotypeNames.contains(phenotypeName)) {
  //      parsedData.allPhenotypeNames.add(phenotypeName);
  //      parsedData.allTraits.add(traitName!);
  //    }

  //  }

  //  } // end of if (parsedData.statusText == "Succeeded" )

  // return parsedData;
  // }
}

//class ParsedData {
//  String? statusText;
//  int? studyIndex;
//  String? accession;
//  int? observationsCount;
//  String? studyName;
//  String? studyID;
//  List<String> parsedPhenotypeNames = [];
//  List<dynamic> observations = [];
//  List<String> traits = [];
//  List<String> units = [];

 // List<String> allPhenotypeNames = []; // New list for all possible phenotypes
 // List<String> allTraits = []; // New list for all possible traits
//}
