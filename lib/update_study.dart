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
        TextEditingController(text: name); // <-- Default study
    final TextEditingController descriptionController = TextEditingController(
        text: description); // <-- Default description

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Edit Existing Study", style: TextStyle(fontSize: 20)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Form(
            key: formKey,
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  String studyName = nameController.text.trim();
                  String studyDescription = descriptionController.text.trim();

                  //print("StudyName: $studyName");
                  //print("StudyDescription: $studyDescription");
                  //print("StudyID: ${this.id}");

                  bool successFlag = await updateData(
                      studyName, studyDescription); //review parameters
                  //print('Success $successFlag');

                  if (successFlag) {
                    Navigator.of(context).pop();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const GrassrootsStudies()),
                      (_) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating")));
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

  Future<bool> updateData(String name, String description) async {
    bool successFlag = false;
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Submit Field Trial Study",
          "start_service": true,
          "parameter_set": {
            "parameters": [
              {"param": "ST Id", "current_value": id, "group": "Study"},
              {
                "param": "ST Description",
                "current_value": description,
                "group": "Study"
              },
              {"param": "ST Name", "current_value": name, "group": "Study"}
            ]
          }
        }
      ]
    });

    Map<String, dynamic> response =
        await GrassrootsRequest.sendRequest(requestString, 'private');

    Map<String, dynamic>? serviceResult = response['results']?[0];

    if (serviceResult != null) {
      //String? status = service_result['status_text'];
      String? jobUuid = serviceResult['job_uuid'];
      //if ((status != null) && (status == 'Succeeded')) {
      if (jobUuid != null) {
        successFlag = true;
      }
    }
    return successFlag;
  }
}
