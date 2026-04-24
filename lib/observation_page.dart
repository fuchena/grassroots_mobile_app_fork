//observation_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'grassroots_request.dart';

class ObservationPage extends StatefulWidget {
  final String studyName;
  final String studyID;
  final String serverResponse;
  final String detectedQRCode;
  final List<String> phenotypeNames;
  final List<String> traits;
  final List<String> allPhenotypeNames;
  final List<String> allTraits;

  ObservationPage({
    required this.studyName,
    required this.studyID,
    required this.serverResponse,
    required this.phenotypeNames,
    required this.detectedQRCode,
    required this.traits,
    required this.allPhenotypeNames,
    required this.allTraits,
  });

  @override
  _ObservationPageState createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  bool hasSuccessfullySubmitted = false; // State variable
  String? accession;

  @override
  void initState() {
    super.initState();
    //print('-----------------All Phenotype Names: ${widget.allPhenotypeNames}');
    print('*  detectedQRCode: ${widget.detectedQRCode}');

    _parseServerResponse();
  }

  TextEditingController measurementController = TextEditingController();
  final TextEditingController optionalNoteController = TextEditingController();
  String? selectedTrait;
  DateTime? selectedDate;
  DateTime? selectedEndDate;
  final _formKey = GlobalKey<FormState>();

  String clearCacheRequest(String studyID) {
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

  String createGrassrootsRequest({
    required String detectedQRCode,
    required String? selectedTrait,
    required String measurement,
    required String dateString,
    String? note,
  }) {
    final requestMap = {
      "services": [
        {
          "so:name": "Edit Field Trial Rack",
          "start_service": true,
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {"param": "RO Id", "current_value": detectedQRCode, "group": "Plot"},
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
              },
            ]
          }
        }
      ]
    };

    // Convert map to a JSON string
    return jsonEncode(requestMap);
  }

  // Parse the serverResponse to extract the Accession value
  void _parseServerResponse() {
    final matches = RegExp(r'Accession: ([^\n]+)').allMatches(widget.serverResponse);
    if (matches.isNotEmpty && matches.first.groupCount >= 1) {
      accession = matches.first.group(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper function to clear form and reset state
    void clearForm() {
      _formKey.currentState!.reset();
      setState(() {
        selectedTrait = null; // Reset the dropdown
        selectedDate = null; // Reset the date picker
        measurementController.clear(); // Clear the text field
        // Any other controllers or variables should be reset here
      });
    }

    // Helper function to show snackbar with a message
    void showSnackBarMessage(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Observation'),
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Study Name: ${widget.studyName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              //Text('Details: ${widget.serverResponse}', textAlign: TextAlign.center),
              if (accession != null)
                Padding(
                  padding: const EdgeInsets.only(top: 36.0), // This will add space above the Accession Text
                  child: Text('Accession: $accession', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  //child: Text('$widget.serverResponse', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
                ),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedTrait,
                hint: Text("Select phenotype"),
                onChanged: (newValue) {
                  setState(() {
                    selectedTrait = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a trait';
                  }
                  return null;
                },
                items: List<DropdownMenuItem<String>>.generate(
                  widget.allPhenotypeNames.length,
                  (index) => DropdownMenuItem<String>(
                    value: widget.allPhenotypeNames[index],
                    child: Text(
                      widget.allTraits[index],
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ),

              TextFormField(
                controller: measurementController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Add measurement",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a measurement';
                  }
                  return null;
                },
              ),

              // Date Picker
              ListTile(
                title: Text("Select date"),
                subtitle: Text(
                  selectedDate != null ? '${selectedDate!.toLocal()}'.split(' ')[0] : 'No date chosen',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000), // Adjust the range as needed
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != selectedDate)
                    setState(() {
                      selectedDate = picked;
                    });
                },
              ),

              // Add Optional Note Field
              TextFormField(
                controller: optionalNoteController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: "Add optional note",
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 255) {
                    return 'Note is too long';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),
              SizedBox(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // If the form is valid, display a Snackbar and print form values.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Processing Data')),
                        );

                        print('detectedQRCode: ${widget.detectedQRCode}');
                        print('studyID: ${widget.studyID}');
                        print('Selected Trait: $selectedTrait');
                        print('Measurement: ${measurementController.text}');
                        print('Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}');
                        print('Optional Note: ${optionalNoteController.text}');

                        try {
                          // Create the primary request string from the form inputs
                          String jsonString = createGrassrootsRequest(
                            detectedQRCode: widget.detectedQRCode,
                            selectedTrait: selectedTrait,
                            measurement: measurementController.text,
                            dateString: DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now()),
                            note: optionalNoteController.text.isNotEmpty ? optionalNoteController.text : null,
                          );

                          print('JSON Request: $jsonString');

                          // Send the primary request to the server and await the response
                          var response = await GrassrootsRequest.sendRequest(jsonString, 'private');

                          // Handle the response data
                          print('Response from server: $response');

                          // Optionally show a success dialog or snackbar message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Data successfully submitted')),
                          );

                          // If the code reaches this point, it means the request was successful
                          // Update the flag here
                          setState(() {
                            hasSuccessfullySubmitted = true;
                          });

                          // After the primary request is successful, initiate the secondary request
                          // Create the cache clear request string using the studyID
                          String cacheClearRequestJson = clearCacheRequest(widget.studyID);
                          print('CACHE Request: $cacheClearRequestJson');
                          // Fire-and-forget the clear cache request, no await used
                          GrassrootsRequest.sendRequest(cacheClearRequestJson, 'queen_bee_backend').then((cacheResponse) {
                            // Log the cache clear response
                            print('+++Cache clear response: $cacheResponse');
                          }).catchError((error) {
                            // Log any errors from the cache clear request
                            print('Error sending cache clear request: $error');
                          });
                        } catch (e) {
                          // Handle any errors that occur during the primary request
                          print('Error sending request: $e');
                          // Optionally show an error dialog or snackbar message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to submit data')),
                          );
                        } finally {
                          // Clear the form fields after processing the request
                          clearForm();
                        }
                      }
                    },
                    child: Text('Submit Observation'),
                  ), // ElevatedButton
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (hasSuccessfullySubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Refreshing observation')),
            );
          }
          Navigator.pop(context, hasSuccessfullySubmitted); // Send the flag back to the home page
        },
        child: Icon(Icons.arrow_back), //Back Button
      ), //FloatingActionButton
    ); // Scaffold
  }
}
