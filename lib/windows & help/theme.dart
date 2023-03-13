import 'package:flutter/material.dart';

final blue = Color.fromARGB(255, 26, 35, 126);
final lightTheme = ThemeData(
  primarySwatch: MaterialColor(blue.value, {
    50: blue,
    100: blue,
    200: blue,
    300: blue,
    400: blue,
    500: blue,
    600: blue,
    700: blue,
    800: blue,
    900: blue,
  }),
  appBarTheme: const AppBarTheme(
    color: Color.fromARGB(255, 26, 35, 126),
    elevation: 0,
    shadowColor: Colors.blue,
    shape: Border(
        bottom:
            BorderSide(color: Color.fromARGB(255, 255, 193, 7), width: 4.0)),
  ),
);

final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(blue.value, {
      50: blue,
      100: blue,
      200: blue,
      300: blue,
      400: blue,
      500: blue,
      600: blue,
      700: blue,
      800: blue,
      900: blue,
    }),
    appBarTheme: const AppBarTheme(
      color: Color.fromARGB(255, 26, 35, 126),
      elevation: 0,
      shape: Border(
          bottom:
              BorderSide(color: Color.fromARGB(255, 255, 193, 7), width: 4.0)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromARGB(255, 26, 35, 126),
    ),
    dividerColor: const Color.fromARGB(200, 255, 193, 7),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(
        color: Color.fromARGB(255, 255, 193, 7),
      ),
    ));

class ThemeProvider extends ChangeNotifier {
  bool _isDarkModeEnabled = false;

  bool get isDarkModeEnabled => _isDarkModeEnabled;

  void toggleTheme(bool isDarkModeEnabled) {
    _isDarkModeEnabled = isDarkModeEnabled;
    notifyListeners();
  }
}
