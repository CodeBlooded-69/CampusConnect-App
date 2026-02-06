import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  // --- EXISTING METHODS (Keep these) ---
  Future<void> setGlobal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_global', value);
  }

  Future<void> setMaxDistance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('max_distance', value);
  }

  Future<void> setAgeRange(RangeValues range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('age_min', range.start);
    await prefs.setDouble('age_max', range.end);
  }

  // --- NEW METHODS (Add these) ---

  Future<void> setPhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phone);
  }

  Future<void> setLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location', location);
  }

  // --- UPDATED LOAD METHOD ---
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'is_global': prefs.getBool('is_global') ?? true,
      'max_distance': prefs.getDouble('max_distance') ?? 109.0,
      'age_min': prefs.getDouble('age_min') ?? 18.0,
      'age_max': prefs.getDouble('age_max') ?? 30.0,
      // Load new values (with defaults)
      'phone_number': prefs.getString('phone_number') ?? "91 84460 29314",
      'location': prefs.getString('location') ?? "Bengaluru, India",
    };
  }

  void setLiveLocation(bool value) {}
}
