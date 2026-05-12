import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grassroots_field_trials/caching.dart';
import 'package:grassroots_field_trials/grassroots_request.dart';
import 'package:grassroots_field_trials/measured_variables.dart';
import 'package:grassroots_field_trials/search_phenotypes.dart';
import 'package:grassroots_field_trials/utils_service.dart';
import 'package:hive/hive.dart';

import 'package:grassroots_field_trials/api_requests.dart';
import 'package:grassroots_field_trials/backend_request.dart';

import 'global_variable.dart';

import 'server.dart';

class NewStudyPage extends StatefulWidget {
  String? study_name;

  NewStudyPage({super.key,
    this.study_name,
  });

  @override
  _NewStudyPageState createState() => _NewStudyPageState();
}

class _NewStudyPageState extends State<NewStudyPage> {
  final TextEditingController _trials_controller = TextEditingController();
  final TextEditingController _locations_controller = TextEditingController();
  bool _is_loading = true;
  List<Map<String, String>> _trials = []; // Store both name and ID

  List<Map<String, String>> _locations = []; // Store both name and ID

  MeasuredVariablesModel _model =
      MeasuredVariablesModel("Selected Phenotypes List");

  final GlobalKey<FormState> _form_key = GlobalKey<FormState>();

  String? _name;
  String? _description;

  int _num_rows = 1;
  int _num_columns = 1;

  String? _selected_trial_id;
  String? _selected_location_id;

  @override
  void initState() {
    super.initState();

    fetchTrials();
    fetchLocations();
  }

  @override
  void dispose() {
    // Dispose of your controllers here

    // Call the dispose method of the superclass at the end
    super.dispose();
  }

  void updateMeasuredVariablesList(MeasuredVariablesModel model) {
    setState(() {
      _model = model;
    });
  }

  Future<MeasuredVariablesModel?> _navigateAndDisplaySelection(
      BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final MeasuredVariablesModel? result = await Navigator.push(
      context,
      // Create the SelectionScreen in the next step.
      MaterialPageRoute(builder: (context) => const SearchPhenotypesPage()),
    );

    // When a BuildContext is used from a StatefulWidget, the mounted property
    // must be checked after an asynchronous gap.
    if (!context.mounted) {
      return null;
    }

    if (result != null) {
      List<MeasuredVariable> mvs = result.values;

      for (int i = 0; i < mvs.length; ++i) {
        print(
            ">>> _navigateAndDisplaySelection () returned $i: ${mvs[i].variableName}");
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    MeasuredVariablesListWidget phenotypesWidget =
        MeasuredVariablesListWidget("Selected Phenotypes List", _model);

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Reset the image state
              setState(() {});

              // Pop the current route
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Create a Study'),
        ),
        body: ListenableBuilder(
            listenable: _model,
            builder: (BuildContext context, Widget? child) {
              // We rebuild the ListView each time the list changes,
              // so that the framework knows to update the rendering.
              final List<MeasuredVariable> values =
                  _model.values; // copy the list

              return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                      child: Form(
                        key: _form_key,
                      child: Column(children: <Widget>[
                    TextFormField(
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Study name'),

                      onChanged: (String? newValue) {
                        setState(() {
                          _name = newValue;
                          print("set _name to $_name");
                        });
                      },

                      validator: UtilsService.validateStringField,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Study Description'),

                      onChanged: (String? newValue) {
                        setState(() {
                          _description = newValue;
                        });
                      },

                      validator: UtilsService.validateStringField,
                    ),

                    const SizedBox(height: 10),

                    // Trials menu
                    FormField<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (_) => UtilsService.validateDropdownField(_selected_trial_id),
                      builder: (FormFieldState<String> field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownMenu<StringLabel>(
                              expandedInsets: EdgeInsets.zero, // full width
                              requestFocusOnTap: true,
                              dropdownMenuEntries: GetTrialsAsList(),
                              controller: _trials_controller,
                              enableFilter: true,
                              label: const Text(
                                  "Choose the Field Trial that this study is a part of..."),
                              helperText: "Select a Trial",
                              trailingIcon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).primaryColor,
                              ),
                              textStyle:
                                  TextStyle(color: Theme.of(context).primaryColor),
                              inputDecorationTheme: InputDecorationTheme(
                                labelStyle:
                                    TextStyle(color: Theme.of(context).primaryColor),
                                helperStyle:
                                    TextStyle(color: Theme.of(context).primaryColor),
                              ),

                              /*
                                inputDecorationTheme: InputDecorationTheme(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  constraints: BoxConstraints.tight(const
                                  Size.fromHeight(40)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                */

                              menuHeight: 500,
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).canvasColor),
                              ),

                              onSelected: (StringLabel? trial) {
                                setState(() {
                                  if (trial != null) {
                                    _selected_trial_id = trial.id;
                                  } else {
                                    _selected_trial_id = null;
                                  }
                                });
                                field.didChange(_selected_trial_id);
                              },
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                                child: Text(
                                  field.errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Locations menu
                    FormField<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (_) =>
                          UtilsService.validateDropdownField(_selected_location_id),
                      builder: (FormFieldState<String> field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownMenu<StringLabel>(
                              expandedInsets: EdgeInsets.zero, // full width
                              requestFocusOnTap: true,
                              dropdownMenuEntries: GetLocationsAsList(),
                              controller: _locations_controller,
                              enableFilter: true,
                              label:
                                  const Text("Choose the Location for this study..."),
                              helperText: "Select a Location",
                              trailingIcon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).primaryColor,
                              ),
                              textStyle:
                                  TextStyle(color: Theme.of(context).primaryColor),
                              inputDecorationTheme: InputDecorationTheme(
                                labelStyle:
                                    TextStyle(color: Theme.of(context).primaryColor),
                                helperStyle:
                                    TextStyle(color: Theme.of(context).primaryColor),
                              ),

                              /*
                                inputDecorationTheme: InputDecorationTheme(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  constraints: BoxConstraints.tight(const
                                  Size.fromHeight(40)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                */

                              menuHeight: 500,
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).canvasColor),
                              ),

                              onSelected: (StringLabel? location) {
                                setState(() {
                                  if (location != null) {
                                    _selected_location_id = location.id;
                                  } else {
                                    _selected_location_id = null;
                                  }
                                });
                                field.didChange(_selected_location_id);
                              },
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                                child: Text(
                                  field.errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Number of plot rows
                    TextFormField(
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: const InputDecoration(
                          labelText: "Number of rows of plots"),
                      initialValue: _num_rows.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ], // Only numbers can be entered

                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          int? c = int.tryParse(newValue);

                          if (c != null) {
                            setState(() {
                              _num_rows = c;
                              print("set rows to $_num_rows");
                            });
                          }
                        }
                      },
                      validator: UtilsService.validateNumberField,
                    ),

                    const SizedBox(height: 10),

                    // Number of plot columns
                    TextFormField(
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: const InputDecoration(
                          labelText: "Number of columns of plots"),
                      initialValue: _num_columns.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ], // Only numbers can be entered

                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          int? c = int.tryParse(newValue);

                          if (c != null) {
                            setState(() {
                              _num_columns = c;
                              print("set columns to $_num_columns");
                            });
                          }
                        }
                      },
                      validator: UtilsService.validateNumberField,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () async {
                            /*
                            MeasuredVariablesModel? m = await _navigateAndDisplaySelection (context);

                            if (m != null) {
                              print ("ABOUT TO SET STATE WITH ${m.length} values");
                              setState(() {
                                phenotypes_widget.addValues (m.values);
                              });
                            }
    */

                            final List<MeasuredVariable>? selectedMvs =
                                await showSearch<List<MeasuredVariable>>(
                              context: context,
                              delegate: MeasuredVariableSearchDelegate(
                                //Fresh delegate per search open
                                "search new phenotypes",
                              ),
                            );

                            if (selectedMvs != null) {
                              for (int i = 0; i < selectedMvs.length; ++i) {
                                print("$i: ${selectedMvs[i].variableName}");
                              }

                              setState(() {
                                // Call setState to refresh the page.
                                phenotypesWidget.addValues(selectedMvs);
                              });
                            }
                          },
                        ),
                        const Text("Phenotypes"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    phenotypesWidget,

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate will return true if the form is valid, or false if
                          // the form is invalid.
                          if (_form_key.currentState!.validate()) {
                            // Process data.
                            String userName = "user name";
                            //String? user_email = await GlobusAuthService.getEmail();
                            String? userEmail;
                            List<MeasuredVariable> phenotypes =
                                phenotypesWidget.getSelectedVariables();
                            final String? name = _name;
                            final String? trialId = _selected_trial_id;
                            final String? locationId = _selected_location_id;

                            if (GrassrootsConfig.log_level >= LOG_INFO) {
                              print("name $name");
                              print("trial_id $trialId");
                              print("location_id $locationId");
                              print("phenotypes ${phenotypes.length}");
                              print("rows $_num_rows");
                              print("columns $_num_columns");
                            }

                            if (name != null) {
                              if (trialId != null) {
                                if (locationId != null) {
                                  print("submitting");
                                  bool successFlag = await submitStudy(
                                      name,
                                      _description ?? '',
                                      trialId,
                                      locationId,
                                      userEmail,
                                      userName,
                                      _num_rows,
                                      _num_columns,
                                      phenotypes);
                                  Icon icon;
                                  String message;

                                  if (successFlag) {
                                    icon = const Icon(Icons.check_circle_outline,
                                        color: Colors.green);
                                    message =
                                        "Study $name created successfully";
                                  } else {
                                    icon = const Icon(Icons.error_outline,
                                        color: Colors.red);
                                    message = "Failed to create Study $name";
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          icon,
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              message,
                                              style:
                                                  const TextStyle(fontSize: 16.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  print("no location id");
                                }
                              } else {
                                print("no trial id");
                              }
                            } else {
                              print("no study name");
                            }
                          } else {
                            print("failed to validate");
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ]
                          // )
                          ))));
            }));
  }


  void fetchTrials() async {
    setState(() {
      _is_loading = true;
    });

    try {
      List<Map<String, String>> trials = await _FetchData(
          backendRequests.fetchAllTrials, CACHE_TRIALS, "Trial");

      if (mounted) {
        setState(() {
          _is_loading = true;
          _trials = trials;
          _is_loading = false;
        });
      }
    } catch (e) {
      print('Error fetching: $e');
      if (mounted) {
        setState(() {
          _is_loading = false;
        });
      }
    }
  }

  void fetchLocations() async {
    setState(() {
      _is_loading = true;
    });

    try {
      List<Map<String, String>> locations = await _FetchData(
          backendRequests.fetchAllLocations, CACHE_LOCATIONS, "Location");

      if (mounted) {
        setState(() {
          _is_loading = true;
          _locations = locations;
          _is_loading = false;
        });
      }
    } catch (e) {
      print('Error fetching s: $e');
      if (mounted) {
        setState(() {
          _is_loading = false;
        });
      }
    }
  }

  Future<List<Map<String, String>>> _FetchData(
      Future<List<Map<String, String>>> Function() restApiCall,
      final String cacheName,
      final String datatype) async {
    List<Map<String, String>> data = [];
    bool healthyFlag =
        await ApiRequests.isServerHealthy(); //use the one from server model?

    /*
     * If the server are online then get the live data
     */
    if (healthyFlag) {
      data = await restApiCall();
    } else {
      /* Use any cached data */
      var box = await Hive.openBox<IdName>(cacheName);

      final int numEntries = box.length;

      for (int i = 0; i < numEntries; i++) {
        Map<String, String> entry = <String, String>{};
        IdName? cachedItem = box.getAt(i);

        if (cachedItem != null) {
          entry["name"] = cachedItem.name;
          entry["id"] = cachedItem.id;

          String dateStr = "";
          dateStr = cachedItem.date.toString();
          data.add(entry);
        }
      }
    }

    return data;
  }

  List<StringEntry> GetTrialsAsList() {
    return _GetEntries(_trials, "Trial");
  }

  List<StringEntry> GetLocationsAsList() {
    return _GetEntries(_locations, "Location");
  }

  List<StringEntry> _GetEntries(
      List<Map<String, String>> mongoObects, final String datatype) {
    List<StringEntry> l = [];

    print("Num ${datatype}s: $mongoObects");

    for (final e in mongoObects) {
      var id = e['id'];

      if (id != null) {
        StringLabel sl = StringLabel(e['name'] ?? 'Unknown $datatype', id);

        StringEntry se = StringEntry(
          label: e['name'] ?? 'Unknown $datatype',
          value: sl,
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.all(Theme.of(context).primaryColor),
          ),
        );

        l.add(se);
      } else {
        print("no id in $e");
      }
    }

    print("num StringEntries for ${datatype}s ${l.length}");
    return l;
  }

  Future<bool> submitStudy(
      final String studyName,
      final String studyDescription,
      final String trialId,
      final String locationId,
      final String? userEmail,
      final String userName,
      final int numRows,
      final int numCols,
      final List<MeasuredVariable> phenotypes) async {
    bool successFlag = false;
    List<String> measuredVariables = [];

    if (phenotypes.isNotEmpty) {
      for (int i = 0; i < phenotypes.length; ++i) {
        measuredVariables.add(phenotypes[i].variableName);
      }
    }

    //final accessToken = await _secureStorage.read(key: 'ACCESS_TOKEN');

    print("measured_variables: $measuredVariables");
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Submit Field Trial Study",
          "start_service": true,
          "parameter_set": {
            "level": "wizard",
            "parameters": [
              {
                "param": "ST Name",
                "current_value": studyName,
                "group": "Study"
              },
              {
                "param": "Field Trials",
                "current_value": trialId,
                "group": "Study"
              },
              {
                "param": "Locations",
                "current_value": locationId,
                "group": "Study"
              },
              {
                "param": "ST Curator name",
                "current_value": userName,
                "group": "Curator"
              },
              {
                "param": "ST Curator email",
                "current_value": "$userEmail",
                "group": "Curator"
              },
              {
                "param": "ST Curator role",
                "current_value": null,
                "group": "Curator"
              },
              {
                "param": "ST Curator affiliation",
                "current_value": null,
                "group": "Curator"
              },
              {
                "param": "ST Curator orcid",
                "current_value": null,
                "group": "Curator"
              },
              {
                "param": "ST Description",
                "current_value": studyDescription,
                "group": "Study"
              },
              {"param": "ST Design", "current_value": null, "group": "Study"},
              {"param": "Photo", "current_value": null, "group": "Study"},
              {
                "param": "ST Image Notes",
                "current_value": null,
                "group": "Study"
              },
              {
                "param": "ST Num Rows",
                "current_value": numRows,
                "group": "Default Plots data"
              },
              {
                "param": "ST Num Columns",
                "current_value": numCols,
                "group": "Default Plots data"
              },
              {
                "param": "This Crop",
                "current_value": "Unknown",
                "group": "Study"
              },
              {
                "param": "Previous Crop",
                "current_value": "Unknown",
                "group": "Study"
              },
              {
                "param": "ST Measured Variables",
                "current_value": measuredVariables,
                "group": "Measured Variables"
              }
            ]
          }
        }
      ]
    });

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      print("About to send:\n$requestString");
    }

    Map<String, dynamic> response =
        await GrassrootsRequest.sendRequest(requestString, 'private');

    Map<String, dynamic>? serviceResult = response['results']?[0];

    if (serviceResult != null) {
      String? status = serviceResult['status_text'];
      if ((status != null) && (status == 'Succeeded')) {
        successFlag = true;

        /*
          * The study was created successfully so we can add it to the
          * list of allowed study ids.
          */

        if (GrassrootsConfig.log_level >= LOG_INFO) {
          print("status $status");
        }

        Map<String, dynamic>? firstResult = serviceResult['results']?[0];
        if (firstResult != null) {
          String? studyId = firstResult['title'];

          if (studyId != null) {
            /* Add the study id to the list of allowed studies */
            IdCache.addId(LOCAL_ALLOWED_STUDIES, studyId);
          }
        }
      }
    }

    return successFlag;
  }
}
