import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/caching.dart';
import 'package:grassroots_field_trials/widget_util.dart';
import 'backend_request.dart';
import 'grassroots_request.dart';
//import 'study_details_widget.dart';
import 'new_observation.dart';
import 'table_observations.dart';
import 'global_variable.dart'; // allowedStudyIDs
import 'api_requests.dart';
import 'package:hive/hive.dart';
import 'server.dart';

class GrassrootsStudies extends StatefulWidget {
  const GrassrootsStudies({super.key});

  @override
  GrassrootsPageState createState() => GrassrootsPageState();
}

class GrassrootsPageState extends State<GrassrootsStudies> {
  final TextEditingController studies_controller = TextEditingController();
  // ...existing code...
  bool isLoading = true;
  bool isSingleStudyLoading = false;
  List<Map<String, String>> gps_studies = []; // Store both name and ID
  StringLabel? selectedStudyLabel;
  String? studyTitle;
  String? studyDescription;
  String? programme;
  String? address;
  String? FTrial;
  int numberOfPlots = 0;
  String? selectedPlotId;
  List<String> plotIDs = [];
  List<String> plotDisplayValues = [];
  String? selectedPlotDisplayValue;
  int observationCount = 0;
  Map<String, dynamic>? fetchedStudyDetails;
  Map<String, dynamic>? selectedPlot;
  String? selectedPhenotype;
  String? _selected_plot_accession;
  Map<String, String> traits = {};
  Map<String, String> units = {};

  Map<String, String> variableToTraitMap = {};

  // Moved accession controller to state so we can reuse and dispose properly
  final TextEditingController accession_controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudies(); // Updated to call the new method to fetch all studies
    //_checkAndUpdateAllowedStudyIDs(); // Add this to check for new study IDs
    print("_GrassrootsPageState :: initState () finished");
  }

  @override
  void dispose() {
    studies_controller.dispose();
    accession_controller.dispose();
    super.dispose();
  }

  // ...existing code...
  static Future<void> CheckAndUpdateAllowedStudyIDs() async {
    print('Initial Allowed Study IDs: $allowedStudyIDs');
    bool healthyFlag = await ApiRequests.isServerHealthy();
    List<String> fetchedIDs = [];

    print("healthy_flag $healthyFlag}");

    if (healthyFlag) {
      List<String>? serverIds = await ApiRequests.fetchAllowedStudyIDs();

      if (serverIds != null) {
        for (int i = 0; i < serverIds.length; ++i) {
          fetchedIDs.add(serverIds[i]);
        }
      }

      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print("1: Allowed studies $fetchedIDs");
      }
    } else {
      /* Use any cached data */
      await GetandAddLocallyAllowedStudies(
          CACHE_SERVER_ALLOWED_STUDIES, fetchedIDs);

      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print("2: Allowed studies $fetchedIDs");
      }
    }

    if (GrassrootsConfig.log_level >= LOG_FINEST) {
      print("3: Allowed studies $fetchedIDs");
    }

    /* Add any user-created studies */
    await GetandAddLocallyAllowedStudies(LOCAL_ALLOWED_STUDIES, fetchedIDs);

    if (GrassrootsConfig.log_level >= LOG_FINEST) {
      print("4: Allowed studies $fetchedIDs");
    }

    //setState(() {
    // Add only new IDs to the allowedStudyIDs list
    final int numFetchedIds = fetchedIDs.length;

    for (int i = 0; i < numFetchedIds; i++) {
      final String id = fetchedIDs[i];

      if (!allowedStudyIDs.contains(id)) {
        allowedStudyIDs.add(id);

        if (GrassrootsConfig.log_level >= LOG_FINEST) {
          print('Added new ID to Allowed Study IDs: $id');
        }
      }
    }
    //});

    if (GrassrootsConfig.log_level >= LOG_FINEST) {
      print('Final Allowed Study IDs: $allowedStudyIDs');
    }
  }

  static Future<int> GetandAddLocallyAllowedStudies(
      final String boxName, List<String> ids) async {
    List<String> localIds = await IdCache.getAllEntries(boxName);

    for (String local_id in localIds) {
      ids.add(local_id);

      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print("Getting $local_id from $boxName");
      }
    }

    return localIds.length;
  }

  void fetchStudies() async {
    bool healthyFlag = await ApiRequests.isServerHealthy();

    List<Map<String, String>> studiesData = [];

    setState(() {
      isLoading = true;
    });

    /*
     * If the server are online then get the live data
     */
    if (healthyFlag) {
      try {
        studiesData = await backendRequests.fetchAllStudies();
      } catch (e) {
        print('Error fetching studies: $e');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      /* Use any cached data */
      var box = await Hive.openBox<IdName>(CACHE_STUDIES);

      final int numEntries = box.length;

      for (int i = 0; i < numEntries; i++) {
        Map<String, String> entry = <String, String>{};
        IdName? study = box.getAt(i);

        if (study != null) {
          entry["name"] = study.name;
          entry["id"] = study.id;

          String dateStr = "";
          dateStr = study.date.toString();

          if (GrassrootsConfig.log_level >= LOG_FINEST) {
            print(
                "using cached study ${entry["name"]}, ${entry["id"]} from $dateStr");
          }

          studiesData.add(entry);
        }
      }

      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print("Got ${gps_studies.length} cached studies");
        print("BEGIN gps_studies");
        print("$gps_studies");
        print("END gps_studies");
      }
    }

    if (studiesData.isNotEmpty) {
      if (mounted) {
        setState(() {
          gps_studies = studiesData;

          if (GrassrootsConfig.log_level >= LOG_FINEST) {
            print("got ${gps_studies.length} studies");
          }
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

//////////////////////////////////////////////////////////
// SIMPLE Function to find and process observations
  void processSelectedPhenotype() {
    // Check if both selectedPlot and selectedPhenotype are available
    if (selectedPlot != null && selectedPhenotype != null) {
      List<dynamic> observations = selectedPlot!['rows'][0]['observations'];

      // List to store the raw values
      List<double> rawValues = [];

      // Iterate over observations
      for (var observation in observations) {
        if (observation['phenotype'] != null &&
            observation['phenotype']['variable'] == selectedPhenotype) {
          // If it matches the selected phenotype, extract the raw value
          double rawValue = observation['raw_value']?.toDouble() ?? 0.0;
          rawValues.add(rawValue);
        }
      }

      // For now, let's just print it
      print('Raw values for $selectedPhenotype: $rawValues');
    }
  }

  //////////////////////////////////////////////////////////
  List<Map<String, dynamic>> findRawValuesForSelectedPhenotype() {
    List<Map<String, dynamic>> matchingObservations = [];
    List<dynamic> observations = selectedPlot!['rows'][0]['observations'];

    for (var observation in observations) {
      if (observation['phenotype'] != null &&
          observation['phenotype']['variable'] == selectedPhenotype) {
        //print('Matched observation for phenotype: $selectedPhenotype');
        String formattedDate = '';
        if (observation['date'] != null) {
          try {
            DateTime date = DateTime.parse(observation['date']);
            formattedDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
        matchingObservations.add({
          'raw_value': observation['raw_value'],
          'date': formattedDate,
          'notes': observation['notes'] ?? '',
        });
      }
    }
    return matchingObservations;
  }

//////////////////////////////////////////////////////////
// Function to show the study details dialog
  void _showStudyDetailsDialog(BuildContext context) {
    print('study!');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor:
          Theme.of(context).colorScheme.surface, // Color(0xffff0000), //
          title: Text(
            studyTitle ?? '',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text.rich(TextSpan(
                  children: [
                    TextSpan(
                      text: 'Description: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    TextSpan(
                        text: studyDescription ?? 'Not available',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                )),

                Text.rich(TextSpan(
                  children: [
                    TextSpan(
                      text: 'Programme: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    TextSpan(
                        text: programme ?? 'Not available',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                )),

                Text.rich(TextSpan(
                  children: [
                    TextSpan(
                      text: 'Address: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    TextSpan(
                        text: address ?? 'Not available',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                )),

                Text.rich(TextSpan(
                  children: [
                    TextSpan(
                      text: 'Field Trial: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    TextSpan(
                        text: FTrial ?? 'Not available',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                )),

                Text.rich(TextSpan(
                  children: [
                    TextSpan(
                      text: 'Number of Plots: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    TextSpan(
                        text: '${numberOfPlots ?? 'Not available'}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                )),

                // Other details...
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10)))),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    print('end study');
  }

  Future<void> onNewObservationReturn(Map<String, dynamic> resultData) async {
    if (resultData.isNotEmpty) {
      if (resultData.containsKey('submissionSuccessful') &&
          resultData['submissionSuccessful']) {
        print('*****REFRESHING STUDY DETAILS AFTER SUCCESSFUL OBSERVATION');
        try {
          String? studyId = selectedStudyLabel?.id;
          if (studyId == null) return;

          String cacheClearRequestJson =
          backendRequests.clearCacheRequest(studyId);
          await GrassrootsRequest.sendRequest(
              cacheClearRequestJson, 'queen_bee_backend');
          print('Cache cleared successfully');

          var studyDetails = await backendRequests.fetchSingleStudy(studyId);
          if (!mounted) return;

          _updateStudyAfterReturn(studyDetails, resultData);
        } catch (e) {
          print('Error in fetching study details: $e');
          // Optionally handle the error here, e.g., showing a snackbar message
        }
      }
    }
  }

  // Extracted helper to update state after a new observation is submitted
  void _updateStudyAfterReturn(
      Map<String, dynamic> studyDetails, Map<String, dynamic> resultData) {
    setState(() {
      fetchedStudyDetails = studyDetails;
    });

    if (resultData.containsKey('plotId')) {
      selectedPlotId = resultData['plotId'];

      plotIDs.clear();
      plotDisplayValues.clear();
      observationCount = 0;

      final data = studyDetails['results']?[0]['results']?[0]['data'];
      if (data == null) return;

      final plots = (data['plots'] as List<dynamic>?) ?? [];

      selectedPlot = plots.firstWhere(
            (plot) =>
        plot['rows'] != null &&
            plot['rows'][0]['_id'] != null &&
            plot['rows'][0]['_id']['\$oid'] == selectedPlotId,
        orElse: () => null,
      );

      if (plots.isNotEmpty) {
        for (var plot in plots) {
          if (plot.containsKey('rows') &&
              plot['rows'] is List &&
              plot['rows'].isNotEmpty) {
            var row = plot['rows'][0];
            if (!(row.containsKey('discard') || row.containsKey('blank'))) {
              String plotID = row['_id']['\$oid'];
              String plotIndex = row['study_index'].toString();
              plotIDs.add(plotID);
              plotDisplayValues.add(plotIndex);
            }
          }
        }

        _sortPlotLists();
        _rebuildSelectedPlotVars();
      }

      setState(() {
        selectedPhenotype = null; // Reset phenotype
      });
    }
  }

  // Sort plotIDs and plotDisplayValues together according to numeric display value
  void _sortPlotLists() {
    var combinedList = List<MapEntry<String, String>>.generate(
      plotIDs.length,
          (index) => MapEntry(plotIDs[index], plotDisplayValues[index]),
    );
    combinedList.sort((a, b) =>
        int.parse(a.value).compareTo(int.parse(b.value)));
    plotIDs = combinedList.map((e) => e.key).toList();
    plotDisplayValues = combinedList.map((e) => e.value).toList();
  }

  // Rebuild variableToTraitMap and observationCount for selectedPlotId
  void _rebuildSelectedPlotVars() {
    if (selectedPlot == null) return;

    int index = plotIDs.indexOf(selectedPlotId ?? '');
    if (index != -1) {
      selectedPlotDisplayValue = plotDisplayValues[index];

      var observations = selectedPlot!['rows'][0]['observations'] as List?;
      observationCount = observations?.length ?? 0;

      // Rebuild variableToTraitMap
      variableToTraitMap.clear();
      if (observations != null) {
        for (var observation in observations) {
          if (observation is Map &&
              observation.containsKey('phenotype') &&
              observation['phenotype'].containsKey('variable')) {
            String variable = observation['phenotype']['variable'];
            if (traits.containsKey(variable)) {
              variableToTraitMap[variable] = traits[variable]!;
            }
          }
        }
      }
      print('Updated Variable to Trait Map: $variableToTraitMap');
    }
  }

  List<StringEntry> GetStudiesAsList() {
    List<StringEntry> l = [];

    if (GrassrootsConfig.log_level >= LOG_FINER) {
      print("in GetStudiesAsList ()");
      print("Num studies $gps_studies");
    }

    for (final e in gps_studies) {
      var study = e;

      if (GrassrootsConfig.log_level >= LOG_FINER) {
        print("STUDY: $study");
      }
      var id = study['id'];

      if (id != null) {
        StringLabel sl = StringLabel(study['name'] ?? 'Unknown Study', id);
        Icon icon = GrassrootsConfig.IsStudyEditable(id)
            ? Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        )
            : Icon(
          Icons.lock,
          color: Theme.of(context).primaryColor,
        );

        StringEntry se = StringEntry(
          label: study['name'] ?? 'Unknown Study',
          value: sl,
          style: ButtonStyle(
            foregroundColor:
            WidgetStateProperty.all(Theme.of(context).primaryColor),
          ),
          trailingIcon: icon,
        );

        l.add(se);
      } else {
        print("no id in $study");
      }
    }

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print("num StringEntries for Studies ${l.length}");
    }

    return l;
  }

  GetStudyDetails(selectedStudyId) async {
    Map<String, dynamic> studyDetails = {};

    try {
      // Fetch the study details
      studyDetails =
      await backendRequests.fetchSingleStudy(selectedStudyId!);
    } catch (e) {
      print(">>>>> Couldn't get study $selectedStudyId");
    }

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print("returning\n$studyDetails");
    }

    return studyDetails;
  }

////////////////////// MAIN BUILD ////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    //print("*******GrassrootsStudies build() called******");
    //print('Selected Study: $selectedStudy');
    //print('Selected Plot ID: $selectedPlotId');
    //print('Selected Phenotype: $selectedPhenotype');
    //print('Number of Plots: $numberOfPlots');

    final List<StringEntry> allStudies = GetStudiesAsList();

    // TextEditingController accession_controller =
    //     TextEditingController(text: _selected_plot_accession);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grassroots Studies'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: isSingleStudyLoading
            ? const Center(
            child:
            CircularProgressIndicator()) // Show loading indicator while fetching single study
        //wrap the column in a singlechildscrollview
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //________ Dropdown to select a study.  1st DROPDOWN MENU______
              DropdownMenu(
                requestFocusOnTap: true,
                dropdownMenuEntries: allStudies,
                controller: studies_controller,
                enableFilter: true,
                label: const Text("Search for a study..."),
                helperText: "Select a Study to view or edit",
                trailingIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).primaryColor,
                ),
                textStyle: TextStyle(
                    color: Theme.of(context).primaryColor),
                inputDecorationTheme: InputDecorationTheme(
                  labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor),
                  helperStyle: TextStyle(
                      color: Theme.of(context).primaryColor),
                ),
                menuHeight: 500,
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).canvasColor),
                ),
                onSelected: (StringLabel? studyLabel) async {
                  if (studyLabel != null) {
                    print(
                        "****** selected study: ${studyLabel.id}, ${studyLabel.name}");
                  }

                  setState(() {
                    selectedStudyLabel = studyLabel;
                    isSingleStudyLoading =
                    true; // Start loading the study details
                    // Reset plot lists
                    plotIDs.clear();
                    plotDisplayValues.clear();
                    selectedPlotId =
                    null; // Also reset the selected plot ID
                    selectedPlotDisplayValue = null;
                    observationCount = 0;
                    accession_controller.clear();
                    traits.clear();
                    units.clear();
                    variableToTraitMap.clear();
                  });

                  try {
                    // Fetch the study details
                    if (selectedStudyLabel != null) {
                      String? id = selectedStudyLabel?.id;
                      String? name = selectedStudyLabel?.name;

                      print("****** selectedStudy: $id, $name");

                      if (id != null) {
                        await _loadStudyDetails(id);
                      } else {
                        print("study id is null");
                      }
                    } else {
                      print("****** selectedStudy is NULL");
                    }
                  } catch (e) {
                    print('**Error fetching study details: $e');
                  } finally {
                    setState(() {
                      isSingleStudyLoading =
                      false; // Ensure loading is stopped in all cases
                    });
                  }
                },
              ),

              // End of dropdown to select a study.   END  OF 1st DROPDOWN MENU______
              const SizedBox(height: 20),
              // __________MODAL FOR DISPLAYING STUDY DETAILS______
              if (selectedStudyLabel != null) ...[
                // Button to open the details dialog

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showStudyDetailsDialog(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 20),
                      ),
                      child: const Text(
                        'View Study Details',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40),
/*                    ElevatedButton(
                      onPressed: () async {
                      UpdateStudy(selectedStudyLabel!.id,studyTitle!,
                          studyDescription?? 'Not Available').showLoginPopup(context);
                        },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 3, horizontal: 20),
                      ),
                      child: Text(
                        'Update Study',
                        textAlign: TextAlign.center,
                      ),
                    ),*/
                  ],
                ),

                // TextButton(
                //   onPressed: () => _showStudyDetailsDialog(context),
                //   child: Text('View Study Details'),
                // ),
                const SizedBox(height: 20),
                // __________BUTTON TO ADD NEW OBSERVATION__________
                //if (selectedPlotId?.isNotEmpty == true)
                ElevatedButton(
                  onPressed: selectedPlotId == null
                      ? null
                      : () {
                    // Use Navigator to push NewObservationPage with the required details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NewObservationPage(
                              studyDetails: fetchedStudyDetails!,
                              plotId: selectedPlotId!,
                              plotDetails: selectedPlot ?? {},
                              onReturn: onNewObservationReturn,
                              selectedTraitKey:
                              null, // keep null - parent may pass later
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).canvasColor,
                    textStyle: TextStyle(
                        color: Theme.of(context).primaryColor),
                  ),
                  child: const Text('Add New Observation'),
                ),
                const SizedBox(height: 20),

                // Dropdown to select a plot.  ______2nd DROPDOWN MENU______

                if (plotDisplayValues.isNotEmpty) ...[
                  DropdownMenu(
                    dropdownMenuEntries:
                    List<DropdownMenuEntry<String>>.generate(
                      plotDisplayValues.length,
                          (index) => DropdownMenuEntry<String>(
                          value: plotIDs[index],
                          label: plotDisplayValues[index],
                          style: MenuItemButton.styleFrom(
                              foregroundColor:
                              Theme.of(context).primaryColor)),
                    ),
                    enableFilter: true,
                    textStyle: TextStyle(
                        color: Theme.of(context).primaryColor),
                    label: const Text("Search for a plot..."),
                    helperText: "Select a plot to view or edit",
                    trailingIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).primaryColor,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                      helperStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                    ),
                    menuHeight: 300,
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).canvasColor),
                    ),
                    onSelected: (String? plotEntry) async {
                      setState(() {
                        selectedPlotId = plotEntry;
                        int index = plotIDs.indexOf(plotEntry!);
                        if (index != -1) {
                          selectedPlotDisplayValue =
                          plotDisplayValues[index];
                          selectedPhenotype = null;
                          ///////////// Additional logic when a plot is selected /////
                          /// Example: Count the number of observations in the selected plot
                          var plots =
                          fetchedStudyDetails?['results']?[0]
                          ['results']?[0]['data']
                          ?['plots'] as List<dynamic>?;

                          // Find the plot that matches the selectedPlotId
                          selectedPlot = plots?.firstWhere(
                                (plot) =>
                            plot['rows'] != null &&
                                plot['rows'][0]['_id']['\$oid'] ==
                                    selectedPlotId,
                            orElse: () => null,
                          );

                          if (selectedPlot != null) {
                            // Since we've checked for null, it's safe to use '!'
                            var observations = selectedPlot!['rows']
                            [0]['observations'] as List?;
                            if (observations != null) {
                              var count = observations.length;
                              observationCount = count;

                              if (GrassrootsConfig.log_level >=
                                  LOG_FINER) {
                                print(
                                    "plot has $observationCount observations");
                              }

                              //  **********lists for phenotypes dropdown menu********
                              variableToTraitMap.clear();

                              for (var observation
                              in observations) {
                                if (GrassrootsConfig.log_level >=
                                    LOG_FINER) {
                                  print(
                                      ">>> Observation:  $observation");
                                }

                                if (observation is Map &&
                                    observation
                                        .containsKey('phenotype') &&
                                    observation['phenotype']
                                        .containsKey('variable')) {
                                  String variable =
                                  observation['phenotype']
                                  ['variable'];

                                  print(
                                      'Variable: $variable, Exists in traits: ${traits.containsKey(variable)}');
                                  // Check if the trait exists for this variable and create a DropdownMenuItem
                                  if (traits
                                      .containsKey(variable)) {
                                    String traitName =
                                    traits[variable]!;
                                    variableToTraitMap[variable] =
                                        traitName;
                                  }
                                }
                              }

                              print(
                                  'Variable to Trait Map: $variableToTraitMap');
                            } else {
                              observationCount = 0;
                            }

                            var material = selectedPlot!['rows'][0]
                            ['material'];

                            if (material != null) {
                              _selected_plot_accession =
                              material['accession'];

                              if (GrassrootsConfig.log_level >=
                                  LOG_FINER) {
                                print(
                                    "accession: $_selected_plot_accession");
                              }
                            }
                          }
                        }

                        print(
                            "setting accession controller text to $_selected_plot_accession");
                        accession_controller.text =
                            _selected_plot_accession ?? '';
                      });
                      // Additional logic when a plot is selected, if needed
                      print(
                          'Selected Plot ID: $plotEntry'); // Print the actual plot ID to console
                    },
                  ),

                  const SizedBox(height: 20),
                  ///// Accession field /////

                  TextField(
                    controller: accession_controller,
                    onSubmitted: (accession) async {
                      print("accession $accession");

                      String? plotId = selectedPlotId;
                      String? studyId = selectedStudyLabel?.id;

                      if ((plotId != null) && (studyId != null)) {
                        // Create the JSON request
                        String jsonString = backendRequests
                            .GetSubmitAccessionRequest(
                          studyId: studyId,
                          plotId: plotId,
                          accession: accession,
                        );

                        if (GrassrootsConfig.log_level >=
                            LOG_FINER) {
                          print('Request to server: $jsonString');
                        }

                        bool successFlag = false;
                        String message =
                            "Failed to update accession to $accession";

                        if (jsonString != "{}") {
                          try {
                            var response =
                            await GrassrootsRequest.sendRequest(
                                jsonString, 'private');

                            if (GrassrootsConfig.log_level >=
                                LOG_INFO) {
                              print(
                                  'Response from server: $response');
                            }

                            String? statusText = response['results']
                            ?[0]['status_text'];
                            if ((statusText != null) &&
                                (statusText == 'Succeeded')) {
                              message =
                              "Updated accession to $accession";
                              successFlag = true;
                            } else {}
                          } catch (e) {
                            print("failed to send request $e");
                            message =
                            "Failed to complete request to update accession to $accession";
                          }
                        }

                        WidgetUtil.ShowSnackBar(
                            context, message, successFlag);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Accession',
                      //hintText: 'The accession for the material in this plot',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                      hintStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                    ),
                    keyboardType: TextInputType.text,

                    style: TextStyle(
                        color: Theme.of(context).primaryColor),

                    //maxLines: 1, // Allow multiline input
                  ),
                ], // end if (plotDisplayValues is not empty)

                const SizedBox(height: 20),
                if (observationCount > 0) ...[
                  DropdownMenu(
                    dropdownMenuEntries:
                    variableToTraitMap.entries.map((entry) {
                      return DropdownMenuEntry<String>(
                        value: entry
                            .key, // The variable name as the value
                        label: entry
                            .value, // The trait name as the display text
                        style: MenuItemButton.styleFrom(
                            foregroundColor:
                            Theme.of(context).primaryColor),
                      );
                    }).toList(),
                    initialSelection: selectedPhenotype,
                    enableFilter: true,
                    textStyle: TextStyle(
                        color: Theme.of(context).primaryColor),
                    label: const Text("Select Phenotype..."),
                    helperText:
                    "Select a Phenotype to view or edit",
                    trailingIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).primaryColor,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                      helperStyle: TextStyle(
                          color: Theme.of(context).primaryColor),
                    ),
                    onSelected: (String? newValue) {
                      setState(() {
                        selectedPhenotype = newValue;
                      });
                      //processSelectedPhenotype();
                      List<Map<String, dynamic>> rawValues =
                      findRawValuesForSelectedPhenotype();
                      // Display the dialog with the ObservationTable
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // find selectedphenotype in units and assign it to displayUnit
                          String displayUnit = 'Some Unit'; //
                          if (units
                              .containsKey(selectedPhenotype)) {
                            displayUnit = units[selectedPhenotype]!;
                          }
                          // find selectedphenotype in traits and assign it to displayTrait
                          String displayTrait = 'Some trait';
                          if (traits
                              .containsKey(selectedPhenotype)) {
                            displayTrait =
                            traits[selectedPhenotype]!;
                          }

                          return Dialog(
                            child: SingleChildScrollView(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(
                                      16.0),
                                  color:
                                  Theme.of(context).canvasColor,
                                ),
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(displayTrait,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: Theme.of(context)
                                                .primaryColor)),
                                    const SizedBox(height: 10),
                                    Text('Unit: $displayUnit',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Theme.of(context)
                                                .primaryColor)),
                                    const SizedBox(height: 20),
                                    if (rawValues.isEmpty)
                                      Text('No Data Found',
                                          style: TextStyle(
                                              color: Theme.of(
                                                  context)
                                                  .primaryColor))
                                    else
                                      ObservationTable(
                                          rawValues: rawValues),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ); // End of showDialog
                    },
                    menuHeight: 300,
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).canvasColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ], // IF studyTitle is not null
            ],
          ),
        ),
      ),
    );
  }

  // Extracted method used inside onSelected to fetch and parse study details
  Future<void> _loadStudyDetails(String id) async {
    var studyDetails = await backendRequests.fetchSingleStudy(id);
    if (studyDetails.isEmpty) {
      print("empty study for $id");
      return;
    }

    final studyJson = studyDetails['results']?[0]['results']?[0]['data'];
    if (studyJson == null) {
      print(">>>>>> failed to get study info");
      return;
    }

    // Build plot lists
    plotIDs.clear();
    plotDisplayValues.clear();

    final plots = (studyJson['plots'] as List<dynamic>?) ?? [];
    int nPlots = 0;
    for (var plot in plots) {
      if (plot.containsKey('rows') &&
          plot['rows'] is List &&
          plot['rows'].isNotEmpty) {
        var row = plot['rows'][0];
        if (!(row.containsKey('discard') || row.containsKey('blank'))) {
          String plotID = row['_id']['\$oid'];
          String plotIndex = row['study_index'].toString();
          plotIDs.add(plotID);
          plotDisplayValues.add(plotIndex);
          nPlots++;
        }
      }
    }

    // Build traits & units
    traits.clear();
    units.clear();
    if (studyJson.containsKey('phenotypes')) {
      var phenotypes = studyJson['phenotypes'] as Map<String, dynamic>;
      phenotypes.forEach((key, value) {
        if (value.containsKey('definition')) {
          var definition = value['definition'];
          try {
            String variableName = definition['variable']['so:name'];
            String traitName = definition['trait']['so:name'];
            traits[variableName] = traitName;
            units[variableName] = definition['unit']['so:name'];
          } catch (e) {
            // ignore malformed phenotype
          }
        }
      });
      print('Dictionary of traits: $traits');
      print('Dictionary of units: $units');
    }

    // Sort plots
    _sortPlotLists();

    setState(() {
      numberOfPlots = nPlots;
      fetchedStudyDetails = studyDetails;
      studyTitle = studyDetails['results']?[0]['results']?[0]['title'];
      studyDescription = studyJson['so:description'];
      programme = studyJson['parent_program']?['so:name'];
      address = studyJson['address']?['name'];
      FTrial = studyJson['parent_field_trial']?['so:name'];
    });

    print('Number of Plots: $nPlots');
    print('Plot IDs: $plotIDs');
    print('Plot Display Values: $plotDisplayValues');
    print('Selected Study ID: $selectedStudyLabel?.id');
    print('Study Title: $studyTitle');
    print('Study Description: $studyDescription');
    print('Study Programme: $programme');
  }
}