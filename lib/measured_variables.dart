import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/backend_request.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:grassroots_field_trials/global_variable.dart';

/*
  "unit": {
    "so:name": "cm",
    "so:sameAs": "ROTH_UNIT:000456"
  },
  "so:name": "<b>Height</b>",
  "@type": "Grassroots:MeasuredVariable",
  "variable": {
    "so:name": "StbHt_Fh_cm",
    "so:sameAs": "ROTH_VARIABLE:000160"
  },
  "trait": {
    "so:name": "Stubble <b>height</b>",
    "so:sameAs": "ROTH_TRAIT:000160",
    "so:description": "<b>Height</b> of stubble after harvesting",
    "abbreviation": "StbHt"
  },
  "id": "6095037102700f511f5e5111",
  "type_description": "Measured Variable",
  "measurement": {
    "so:name": "<b>Height</b>",
    "so:sameAs": "ROTH_MEAS:000482",
    "so:description": "Stubble <b>height</b>, measured from ground to top of stubble, if stubble lodged, then the true length of the stubble, measured at the angle of the stubble."
  },
*/

class MeasuredVariable {
  final String id;
  final String unitName;
  final String traitName;
  final String? traitDescription;
  final String measurementName;
  final String? measurementDescription;
  final String variableName;
  bool selected;

  MeasuredVariable(
      this.id,
      this.unitName,
      this.traitName,
      this.traitDescription,
      this.measurementName,
      this.measurementDescription,
      this.variableName,
      this.selected,
      );

  factory MeasuredVariable.fromJson(Map<String, dynamic> json) {
    if (GrassrootsConfig.log_level >= LOG_FINEST) {
      print(">>> json $json");
    }

    final id = json["id"] ?? "";
    if (id.isEmpty) throw Exception("Missing id");

    final unit = _getChild(json, "unit", "so:name");
    final trait = _getChild(json, "trait", "so:name");
    final traitDescription =
    _getChild(json, "trait", "so:description", optional: true);
    final measurement = _getChild(json, "measurement", "so:name");
    final measurementDescription =
    _getChild(json, "measurement", "so:description", optional: true);
    final variable = _getChild(json, "variable", "so:name");

    return MeasuredVariable(
      id,
      unit,
      trait,
      _nullIfEmpty(traitDescription),
      measurement,
      _nullIfEmpty(measurementDescription),
      variable,
      false,
    );
  }

  static String _getChild(Map<String, dynamic> json, String key, String field,
      {bool optional = false}) {
    final child = json[key];
    if (child == null) {
      if (optional) return "";
      throw Exception("Missing child: $key");
    }
    final value = child[field] ?? "";
    if (value.isEmpty && !optional)
      throw Exception("Missing field: $field in $key");
    return value;
  }

  static String? _nullIfEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}

class MeasuredVariablesModel with ChangeNotifier {
  final List<MeasuredVariable> _values = [];
  final String name;

  MeasuredVariablesModel(this.name);

  List<MeasuredVariable> get values => List.unmodifiable(_values);
  int get length => _values.length;

  void add(MeasuredVariable mv) {
    _values.add(mv);
    notifyListeners();
  }

  List<MeasuredVariable> getSelectedVariables() =>
      _values.where((mv) => mv.selected).toList();

  MeasuredVariable at(int index) => _values[index]; // get method shorthand

  void setValues(List<MeasuredVariable> newValues) {
    _values
      ..clear()
      ..addAll(newValues);
    notifyListeners();
  }

  void addValues(List<MeasuredVariable> newValues) {
    final added = newValues.where((mv) => !_values.contains(mv)).toList();
    if (added.isNotEmpty) {
      _values.addAll(added);
      notifyListeners();
    }
  }
}

class MeasuredVariablesListWidget extends StatefulWidget {
  final MeasuredVariablesModel model;
  final String name;

  MeasuredVariablesListWidget(this.name,
      [MeasuredVariablesModel?
      model]) //[] means the parameter is optional positional.
      : model = model ?? MeasuredVariablesModel(name);

  @override
  State<MeasuredVariablesListWidget> createState() =>
      _MeasuredVariablesListWidgetState();

  void setValues(List<MeasuredVariable> values) => model.setValues(values);
  void addValues(List<MeasuredVariable> values) => model.addValues(values);
  List<MeasuredVariable> getSelectedVariables() => model.getSelectedVariables();
}

class _MeasuredVariablesListWidgetState
    extends State<MeasuredVariablesListWidget> {
  void _toggle(int index) {
    setState(() {
      widget.model.at(index).selected = !widget.model.at(index).selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.model.values;

    if (values.isEmpty) return const SizedBox();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: values.length,
      itemBuilder: (context, index) {
        final mv = values[index];
        final subtitle =
            "${mv.traitName} - ${mv.measurementName} - ${mv.unitName}";

        return ListTile(
          onTap: () => _toggle(index),
          trailing: Checkbox(
            value: mv.selected,
            onChanged: (_) => _toggle(index),
          ),
          title: Text(mv.variableName),
          subtitle: Html(data: subtitle),
        );
      },
    );
  }
}

class MeasuredVariableSearchDelegate
    extends SearchDelegate<List<MeasuredVariable>> {
  final MeasuredVariablesListWidget _listWidget;

  MeasuredVariableSearchDelegate(String name) //constructor
      : _listWidget = MeasuredVariablesListWidget(name);

  @override
  List<Widget>? buildActions(BuildContext context) => [];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, _listWidget.getSelectedVariables()),
  );

  @override
  Widget buildResults(BuildContext context) =>
      FutureBuilder<List<MeasuredVariable>>(
        future: backendRequests.searchMeasuredVariables(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            _listWidget.setValues(snapshot.data!);
          }
          return _listWidget;
        },
      );

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox();
}
