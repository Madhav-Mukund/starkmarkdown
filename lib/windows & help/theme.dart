import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final blue = Color.fromARGB(255, 26, 35, 126);
final yellow = Color.fromARGB(255, 255, 193, 7);
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
    primarySwatch: MaterialColor(yellow.value, {
      50: yellow,
      100: yellow,
      200: yellow,
      300: yellow,
      400: yellow,
      500: yellow,
      600: yellow,
      700: yellow,
      800: yellow,
      900: yellow,
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

  void toggleTheme(bool isDarkModeEnabled) async {
    _isDarkModeEnabled = isDarkModeEnabled;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkModeEnabled', isDarkModeEnabled);
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkModeEnabled = prefs.getBool('isDarkModeEnabled') ?? false;
    if (isDarkModeEnabled != _isDarkModeEnabled) {
      _isDarkModeEnabled = isDarkModeEnabled;
      notifyListeners();
    }
  }

  void updateThemeBasedOnDevice(BuildContext context) {
    final Brightness systemBrightness =
        SchedulerBinding.instance.window.platformBrightness;
    if (systemBrightness == Brightness.dark) {
      if (!_isDarkModeEnabled) {
        _isDarkModeEnabled = true;
        notifyListeners();
      }
    } else {
      if (_isDarkModeEnabled) {
        _isDarkModeEnabled = false;
        notifyListeners();
      }
    }
  }
}
