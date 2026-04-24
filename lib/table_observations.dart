import 'package:flutter/material.dart';

class ObservationTable extends StatelessWidget {
  final List<Map<String, dynamic>> rawValues;

  const ObservationTable({
    Key? key,
    required this.rawValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rawValues.isEmpty) {
      return const Text('No Data Found');
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: Theme.of(context).primaryColor,
                  width: 1,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1.6),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration (
                      color: Theme.of(context).canvasColor,
                      
                    ),
                    children: [
                      Padding(padding: EdgeInsets.all(8.0), child: Text ('Value', 
                        style: TextStyle (
                          backgroundColor: Theme.of (context).canvasColor, 
                          color: Theme.of(context).primaryColor)
                        )
                      ),
                      
                      Padding(padding: EdgeInsets.all(8.0), child: Text ('Date', 
                        style: TextStyle (
                          backgroundColor: Theme.of (context).canvasColor, 
                          color: Theme.of(context).primaryColor)
                        )
                      ),
                      
                      Padding(padding: EdgeInsets.all(8.0), child: Text ('Notes', 
                        style: TextStyle (
                          backgroundColor: Theme.of (context).canvasColor, 
                          color: Theme.of(context).primaryColor)
                        )
                      ),
                    ],
                  ),
                  ...rawValues.map((observation) => TableRow(
                        children: [
                          Padding (
                            padding: EdgeInsets.all(8.0), 
                            child: Text( '${observation['raw_value']}', 
                              style: TextStyle(
                                backgroundColor: Theme.of (context).canvasColor, 
                                color: Theme.of (context).primaryColor)
                            )
                          ),

                          Padding (
                            padding: EdgeInsets.all(8.0), 
                            child: Text( '${observation['date']}', 
                              style: TextStyle(
                                backgroundColor: Theme.of (context).canvasColor, 
                                color: Theme.of (context).primaryColor)
                            )
                          ),

                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              observation['notes'] ?? '',
                              softWrap: false, // Prevents text from wrapping
                              style: TextStyle(
                                backgroundColor: Theme.of (context).canvasColor, 
                                color: Theme.of (context).primaryColor
                              )
                            ),
                          ),

                        ],
                      )),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 4, // Slightly away from the right edge of the screen
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of (context).highlightColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 24,
              color: Theme.of (context).indicatorColor, // Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}
