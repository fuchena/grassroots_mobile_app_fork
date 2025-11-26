import 'package:flutter/material.dart';

class UpdateStudy {
   String studyName;
   String studyDescription;


  UpdateStudy(this.studyName, this.studyDescription);

    void showLoginPopup(BuildContext context) {
    final TextEditingController nameController =
    TextEditingController(text: this.studyName); // <-- Default study
    final TextEditingController descriptionController = TextEditingController(
        text: this.studyDescription); // <-- Default description

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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  String studyName = nameController.text.trim();
                  String studyDescription = descriptionController.text.trim();

                  print("StudyName: $studyName");
                  print("StudyDescription: $studyDescription");

                  Navigator.of(context).pop();
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}