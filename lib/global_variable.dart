// global_variables.dart

import 'package:global_configuration/global_configuration.dart';


List<String> allowedStudyIDs = [
  '64f1e4e77c486e019b4e3017',
  '63bfce1a86ff5b59175e1d66',   // Study 1. Testing/debugging
  '65a532e1536b7214e714a97f', // Glasshouse test study
];

const int HI_OBSERVATIONS = 1;
const int HI_PHOTOS = 2;
const int HI_STUDIES = 3;
const int HI_ALLOWED_IDS = 4;

const String CACHE_STUDIES = "studies_cache";
const String CACHE_TRIALS = "trials_cache";
const String CACHE_LOCATIONS = "locations_cache";
const String CACHE_PROGRAMMES = "programmes_cache";
const String CACHE_MEASURED_VARIABLES = "measured_variables_cache";
const String LOCAL_ALLOWED_STUDIES = "local_allowed_studies";
const String CACHE_SERVER_ALLOWED_STUDIES = "server_allowed_studies_cache";

const int LOG_INFO = 10;
const int LOG_FINE = 20;
const int LOG_FINER = 30;
const int LOG_FINEST = 40;


class GrassrootsConfig {

  static int log_level = LOG_FINER;


  static Future <void> LoadConfig () async {

    /* Load any custom config if it exists */
    try {
      await GlobalConfiguration ().loadFromAsset ("config");
      await GlobalConfiguration ().loadFromAsset ("custom_config");
    } catch (e) {
      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print ("custom_config.json not found");
      }
    }
  }


  static void PrintConfig () {
    print ("GetHost () ${GetHost ()}");
    print ("GetPublicBackendURL () ${GetPublicBackendURL ()}");
    print ("GetPrivateBackendURL () ${GetPrivateBackendURL ()}");
    print ("GetAdminBackendURL () ${GetAdminBackendURL ()}");
    print ("GetPhotoReceiverURL () ${GetPhotoReceiverURL ()}");
  }


  static String? GetPublicBackendURL () {
    return _GetBackendURL ("public");
  }


  static String? GetPrivateBackendURL () {
    return _GetBackendURL ("private");
  }

  static String? GetAdminBackendURL () {
    return _GetBackendURL ("queen_bee");
  }


  static String? GetPhotoReceiverURL () {
    return _GetBackendURL ("photo_receiver");
  }

  static String? GetHost () {
    return GlobalConfiguration().getValue ("host");
  }



  static String? _GetBackendURL (String key) {
    String? url;
    String? host = GetHost ();

    if (host != null) {
      Map <String, dynamic> ? hostConfig = GlobalConfiguration ().getValue (host);  //host_config is a json object mapped to host

      if (hostConfig != null) {
        String? subUrl = hostConfig [key];

        if (subUrl != null) {
          if (host.endsWith ("/")) {
            url = "$host$subUrl";
          } else {
            url = "$host/$subUrl";
          }
        }
      }
    }

    return url;
  }


  static Map <String, dynamic> ? _GetHostConfig () {
    Map <String, dynamic> ? hostConfig;
    String? host = GetHost ();

    if (host != null) {
      hostConfig = GlobalConfiguration ().getValue (host);
    }

    return hostConfig;
  }

  static bool IsStudyEditable (String studyId) {
    /* bool editable_flag = true; */
    bool editableFlag = allowedStudyIDs.contains (studyId);

    return editableFlag;
  }
}
