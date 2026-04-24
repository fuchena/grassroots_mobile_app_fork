



import 'package:flutter/material.dart';

class WidgetUtil {

  static void ShowSnackBar (BuildContext context, String message, bool success_flag) {
    Icon icon = success_flag ?
      Icon (Icons.check_circle_outline, color: Colors.green) :
      Icon (Icons.error_outline, color: Colors.red);

    ScaffoldMessenger.of (context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            SizedBox (width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),

      ),
    );
  }
}
