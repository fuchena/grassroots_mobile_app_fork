import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/grassroots_studies.dart';

import 'grassroots_request.dart';

class UpdateStudy {
  String id;
  String name;
  String description;

  UpdateStudy(this.id, this.name, this.description);

  void showLoginPopup(BuildContext context) {
    final TextEditingController nameController =
        TextEditingController(text: this.name); // <-- Default study
    final TextEditingController descriptionController = TextEditingController(
        text: this.description); // <-- Default description

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Update Study", style: TextStyle(fontSize: 20)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Study Name",
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 3,
                  //obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Description",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async{
                if (_formKey.currentState!.validate()) {
                  String studyName = nameController.text.trim();
                  String studyDescription = descriptionController.text.trim();

                  print("StudyName: $studyName");
                  print("StudyDescription: $studyDescription");
                  print("StudyID: ${this.id}");
                  bool successFlag = await updateStudy(studyName, studyDescription, this.id);
                  print('Success $successFlag');

                  if (successFlag) {
                    Navigator.of(context).pop();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => GrassrootsStudies()),
                          (_) => false,
                    );
                  }

                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> updateStudy(
    final String study_name,
    final String study_description,
    final String id,
  ) async {
    bool success_flag = false;
    String request_string = jsonEncode({
      "services": [
        {
          "so:name": "Submit Field Trial Study",
          "start_service": true,
          "parameter_set": {
            "parameters": [
              {
                "param": "ST Id",
                "current_value": "$id",
                "group": "Study"
              },
              {
                "param": "ST Description",
                "current_value": "$study_description",
                "group": "Study"
              },
              {
                "param": "ST Name",
                "current_value": "$study_name",
                "group": "Study"
              }
            ]
          }
        }
      ]
    });

    Map<String, dynamic> response =
        await GrassrootsRequest.sendRequest(request_string, 'public');

    Map<String, dynamic>? service_result = response['results']?[0];

    if (service_result != null) {
      String? status = service_result['status_text'];
      if ((status != null) && (status == 'Succeeded')) {
        success_flag = true;
      }
    }
    return success_flag;
  }
}
