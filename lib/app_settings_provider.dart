import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider with ChangeNotifier {
  double fontSize;
  bool isDarkMode;

  AppSettingsProvider({this.fontSize = 24, this.isDarkMode = false});

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    fontSize = prefs.getDouble('font_size') ?? 24;
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> updateFontSize(double size) async {
    fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    notifyListeners();
  }

  Future<void> updateDarkMode(bool value) async {
    isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }
} 