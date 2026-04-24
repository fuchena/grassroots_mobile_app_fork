import 'package:flutter/material.dart';

class GeneralDetails extends StatelessWidget {
  final String? studyName;
  final String? serverResponse;
  final String? selectedRawValue;

  const GeneralDetails({
    Key? key,
    required this.studyName,
    required this.serverResponse,
    required this.selectedRawValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // To avoid taking up the whole screen height
      children: [
        if (studyName != null) // Only display if there's a study name
          Text(
            '$studyName',
            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        SizedBox(height: 10), // A spacing of 10 pixels
        Text(
          '$serverResponse',
          style: TextStyle(fontSize: 12, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20), // A spacing of 20 pixels for visual separation
        if (selectedRawValue != null) // Only display if there's a value selected
          Text(
            'Selected Raw Value: $selectedRawValue',
            style: TextStyle(fontSize: 14, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        SizedBox(height: 20), // A spacing of 20 pixels for visual separation
      ],
    );
  }
}
