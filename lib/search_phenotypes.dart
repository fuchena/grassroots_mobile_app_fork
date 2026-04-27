import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/measured_variables.dart';

class SearchPhenotypesPage extends StatelessWidget {
  const SearchPhenotypesPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            MeasuredVariablesModel model = MeasuredVariablesModel ("SearchPhenotypesPage");

            MeasuredVariable mv_0 = MeasuredVariable("id 0", "unit_name 0", "trait_name 0", "trait_descrption 0", "measurement_name 0", "measurement_description 0", "variable_name 0", true);
            MeasuredVariable mv_1 = MeasuredVariable("id 1", "unit_name 1", "trait_name 1", "trait_descrption 1", "measurement_name 1", "measurement_description 1", "variable_name 1", true);

            model.add (mv_0);
            model.add (mv_1);

            Navigator.pop (context, model);
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}



class SelectionButton extends StatefulWidget {
  const SelectionButton({super.key});

  @override
  State<SelectionButton> createState() => _SelectionButtonState();
}

class _SelectionButtonState extends State<SelectionButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _navigateAndDisplaySelection(context);
      },
      child: const Text('Pick an option, any option!'),
    );
  }

  Future<void> _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      // Create the SelectionScreen in the next step.
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  }
}


class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick an option')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () {
                  // Pop here with "Yep"...

                  MeasuredVariablesModel model = MeasuredVariablesModel ("SelectionScreen");

                  MeasuredVariable mv_0 = MeasuredVariable("id 0", "unit_name 0", "trait_name 0", "trait_descrption 0", "measurement_name 0", "measurement_description 0", "variable_name 0", true);
                  MeasuredVariable mv_1 = MeasuredVariable("id 1", "unit_name 1", "trait_name 1", "trait_descrption 1", "measurement_name 1", "measurement_description 1", "variable_name 1", true);

                  model.add (mv_0);
                  model.add (mv_1);

                  Navigator.pop (context, model);

                },
                child: const Text('Ok'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop (context, null);
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}