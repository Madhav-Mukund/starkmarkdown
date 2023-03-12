import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  primarySwatch: Colors.blue,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  appBarTheme: AppBarTheme(
    color: Colors.grey[900],
    elevation: 0,
    shadowColor: Colors.blue,
    shape: const Border(bottom: BorderSide(color: Colors.blue, width: 4.0)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
  ),
  dividerColor: Colors.blue,
);

class ThemeProvider extends ChangeNotifier {
  bool _isDarkModeEnabled = false;

  bool get isDarkModeEnabled => _isDarkModeEnabled;

  void toggleTheme(bool isDarkModeEnabled) {
    _isDarkModeEnabled = isDarkModeEnabled;
    notifyListeners();
  }
}
