// study_details_widget.dart
import 'package:flutter/material.dart';

class StudyDetailsWidget extends StatelessWidget {
  final String studyTitle;
  final String studyDescription;
  final String programme;
  final String address;
  final String FTrial;
  final int numberOfPlots;
  final int observationCount;
  final String selectedPlotId;
  final Function(Map<String, dynamic>) onAddObservation;
  final Map<String, dynamic> selectedPlotDetails;

  StudyDetailsWidget({
    required this.studyTitle,
    required this.studyDescription,
    required this.programme,
    required this.address,
    required this.FTrial,
    required this.numberOfPlots,
    required this.observationCount,
    required this.selectedPlotId,
    required this.onAddObservation,
    required this.selectedPlotDetails,
  });

  @override
  Widget build(BuildContext context) {
    //print('Received plot details in widget: $selectedPlotDetails');



    return  Container(
      color: Theme.of(context).colorScheme.onPrimary,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing code to display study details
        Text(
          '$studyTitle',
          style: TextStyle (fontSize: 18, fontWeight: FontWeight.bold, backgroundColor: Theme.of(context).colorScheme.primary, color: Theme.of(context).colorScheme.onPrimary)
        ),
        SizedBox(height: 10),

        Text(
          'The Description: ${studyDescription.isNotEmpty ? studyDescription : 'Not available'}',
          style: TextStyle (fontSize: 16, fontWeight: FontWeight.bold, backgroundColor: Theme.of(context).colorScheme.primary, color: Theme.of(context).colorScheme.onPrimary)
        ),
        SizedBox(height: 10),
        Text(
          'Programme: ${programme.isNotEmpty ? programme : 'Not available'}',
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 10),
        Text(
          'Field Trial: ${FTrial.isNotEmpty ? FTrial : 'Not available'}',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          'Address: ${address.isNotEmpty ? address : 'Not available'}',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          'Number of Plots: $numberOfPlots',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),

        // Add New Observation Button
        if (selectedPlotId.isNotEmpty)
          ElevatedButton(
            onPressed: () => onAddObservation(selectedPlotDetails),
            child: Text('Add New Observation'),
          ),
      ],
    ),
    );
  }
}
