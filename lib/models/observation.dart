import 'package:grassroots_field_trials/backend_request.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:grassroots_field_trials/grassroots_request.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'observation.g.dart';

@HiveType(typeId: 0)
class Observation extends HiveObject {
  static final String BOX_NAME = "observations";

  @HiveField(0)
  String plotId;

  @HiveField(1)
  String trait;

  @HiveField(2)
  String value;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  String date;

  @HiveField(5)
  String syncStatus;

  @HiveField(6)
  String studyId;

  @HiveField(7)
  String? accession;

  Observation({
    required this.plotId,
    required this.trait,
    required this.value,
    this.notes,
    required this.date,
    required this.syncStatus,
    required this.studyId,
    this.accession,
  });

  Map<String, dynamic> toJson() {
    return {
      'plotId': plotId,
      'trait': trait,
      'value': value,
      'notes': notes,
      'date': date,
      'syncStatus': syncStatus,
      'studyId': studyId,
      'accession': accession,
    };
  }

  /*
   * @param cache_flag Set this to true to add the observation to the local
   * hive db for caching as well as submitting to the server
   * @return 1 upon success, 0 of the request was sent but a genuine error code
   * was returned and -1 if am exception occurred
   */
  Future<int> Submit(bool cache_flag) async {
    int ret = 0;

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print("BEGIN Observation");
      print("studyId ${studyId}");
      print("plotId ${plotId}");
      print("trait ${trait}");
      print("value ${value}");
      print("date ${date}");
      print("accession ${accession}");
      print("notes ${notes}");
      print("END Observation");
    }

    // Create the JSON request
    String jsonString = backendRequests.GetSubmitObservationRequest(
      studyId: studyId,
      plotId: plotId,
      selectedTrait: trait,
      measurement: value,
      dateString: date,
      accession: accession,
      note: notes,
    );

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      print('Request to server: $jsonString');
    }

    bool simulate_offline = false;

    if ((!simulate_offline) && (jsonString != '{}')) {
      try {
        var response =
            await GrassrootsRequest.sendRequest(jsonString, 'private');

        if (GrassrootsConfig.log_level >= LOG_INFO) {
          print('Response from server: $response');
        }

        String? statusText = response['results']?[0]['status_text'];
        if ((statusText != null) && (statusText == 'Succeeded')) {
          ret = 1;
        } else {}
      } catch (e) {
        print("failed to send request ${e}");
        ret = -1;
      }
    }

    if (ret == 1) {
      syncStatus = backendRequests.SYNCED;
    } else {
      syncStatus = backendRequests.PENDING;
    }

    if (cache_flag) {
      bool local_save_flag = await _SaveObservationLocally();

      if (!local_save_flag) {
        print("Failed to save Observation locally");
      }
    }

    return ret;
  }

  Future<bool> _SaveObservationLocally() async {
    bool success_flag = true;

    try {
      // Open the Hive box
      var box = await Hive.openBox<Observation>(Observation.BOX_NAME);

      var uuid = Uuid();
      var obs_id = uuid.v4();

      // Save the observation to the box
      await box.put(obs_id, this);

      // Debug print to confirm the observation was saved
      print('Observation saved locally: ${this.toJson()}');
    } catch (e) {
      // Handle any errors that occur during the save process
      print('Error saving observation locally: $e');
      success_flag = false;
    }

    return success_flag;
  }

  static Future<void> SyncLocalObservations() async {
    try {
      // Open the Hive box
      var box = await Hive.openBox<Observation>(Observation.BOX_NAME);

      // Get all of the entries
      Iterable<dynamic> keys = box.keys;

      for (var key in keys) {
        Observation? o = box.get(key);

        if (o != null) {
          if (o.syncStatus == backendRequests.PENDING) {
            int res = await o.Submit(false);

            if (res == 1) {
              o.syncStatus = backendRequests.SYNCED;

              box.delete(key); //delete not needed in this instance
              box.put(key, o);
            }
          }
        }
      }
    } catch (e) {
      // Handle any errors that occur during the save process
      print('Error saving observation locally: $e');
    }
  }
}
