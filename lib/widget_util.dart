



import 'package:flutter/material.dart';

class WidgetUtil {

  static void ShowSnackBar (BuildContext context, String message, bool successFlag) {
    Icon icon = successFlag ?
      const Icon (Icons.check_circle_outline, color: Colors.green) :
      const Icon (Icons.error_outline, color: Colors.red);

    ScaffoldMessenger.of (context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox (width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),

      ),
    );
  }
}
