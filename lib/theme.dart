import 'package:flutter/material.dart';

final Color _light_primary_color = Color(0xFF2c3e50);

final Color _dark_primary_color = Colors.white;

final ThemeData light_theme = ThemeData(
  brightness: Brightness.light,
  primaryColor: _light_primary_color,
   textTheme: TextTheme(
    displayLarge: TextStyle (color: _light_primary_color),
    displayMedium: TextStyle (color: _light_primary_color),
    displaySmall: TextStyle (color: _light_primary_color),
    headlineLarge: TextStyle (color: _light_primary_color),
    headlineMedium: TextStyle (color: _light_primary_color),
    headlineSmall: TextStyle (color: _light_primary_color),
    titleLarge: TextStyle (color: _light_primary_color),
    titleMedium: TextStyle (color: _light_primary_color),
    titleSmall:TextStyle (color: _light_primary_color),
    bodyLarge: TextStyle (color: _light_primary_color),
    bodyMedium: TextStyle (color: _light_primary_color),
    bodySmall: TextStyle (color: _light_primary_color),
    labelLarge: TextStyle (color: _light_primary_color),
    labelMedium: TextStyle (color: _light_primary_color),
    labelSmall: TextStyle (color: _light_primary_color), 
  ), 
  listTileTheme: ListTileThemeData(
    textColor: _light_primary_color,
    titleTextStyle: TextStyle (color: _light_primary_color),
    subtitleTextStyle: TextStyle (color: _light_primary_color),
    iconColor: _light_primary_color,
  ),  
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all (_light_primary_color),
    checkColor: WidgetStateProperty.all (Colors.white),
  ),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors
        .blueGrey, // Adjust to a swatch that matches your primary color if needed
  ).copyWith(
    secondary: _light_primary_color,
    primary: _light_primary_color,
    surface: Colors.white, // Set the background color to white
  ),
  scaffoldBackgroundColor: Colors.white, // Set the default background color for Scaffold widgets to white
  indicatorColor: _light_primary_color,
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF2c3e50), // Set the AppBar color
    foregroundColor: _dark_primary_color, // Set the AppBar icon and text color
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey, // Button background color
      foregroundColor: _light_primary_color, // Text and icon color
    ),
  ),
  textButtonTheme: TextButtonThemeData (
    style: TextButton.styleFrom(
      foregroundColor: _dark_primary_color,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color: _light_primary_color),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color: _light_primary_color),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(
          color:
              _light_primary_color
      ), // Use primary color for focused border
    ),
  ),
);


final ThemeData dark_theme = ThemeData(
  textTheme: TextTheme(
    displayLarge: TextStyle (color: _dark_primary_color),
    displayMedium: TextStyle (color: _dark_primary_color),
    displaySmall: TextStyle (color: _dark_primary_color),
    headlineLarge: TextStyle (color: _dark_primary_color),
    headlineMedium: TextStyle (color: _dark_primary_color),
    headlineSmall: TextStyle (color: _dark_primary_color),
    titleLarge: TextStyle (color: _dark_primary_color),
    titleMedium: TextStyle (color: _dark_primary_color),
    titleSmall:TextStyle (color:_dark_primary_color),
    bodyLarge: TextStyle (color: _dark_primary_color),
    bodyMedium: TextStyle (color: _dark_primary_color),
    bodySmall: TextStyle (color: _dark_primary_color),
    labelLarge: TextStyle (color: _dark_primary_color),
    labelMedium: TextStyle (color: _dark_primary_color),
    labelSmall: TextStyle (color: _dark_primary_color), 
  ),
  listTileTheme: ListTileThemeData(
    textColor: _dark_primary_color,
    titleTextStyle: TextStyle (color: _dark_primary_color),
    subtitleTextStyle: TextStyle (color: _dark_primary_color),
    iconColor: _dark_primary_color,
  ),  
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all (_dark_primary_color),
    checkColor: WidgetStateProperty.all (Color(0xFF2c3e50)),
  ),
  primaryColor: _dark_primary_color,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors
      .blueGrey, // Adjust to a swatch that matches your primary color if needed
  ).copyWith(
    secondary: _dark_primary_color,
    primary: _dark_primary_color,
    surface: Color(0xFF2c3e50), // Set the background color to white
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: Colors.black, // Set the default background color for Scaffold widgets to white
  indicatorColor: _dark_primary_color,
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF2c3e50), // Set the AppBar color
    foregroundColor: _dark_primary_color, // Set the AppBar icon and text color
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF2c3e50), // Button background color
      foregroundColor: _dark_primary_color, // Text and icon color
    ),
  ),
  textButtonTheme: TextButtonThemeData (
    style: TextButton.styleFrom(
      foregroundColor: _dark_primary_color,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color:_dark_primary_color),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color: _dark_primary_color),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(
          color: _dark_primary_color, // Use primary color for focused border
      ),
    ),
  ),
);
