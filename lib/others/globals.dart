import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final String serviceUuid = "0000fee0-0000-1000-8000-00805f9b34fb";
final String characteristicUuid = "0000fee1-0000-1000-8000-00805f9b34fb";

Future<bool> autocheckFirmwareUpdates() async {
  final prefs = await SharedPreferences.getInstance();
  bool? check = prefs.getBool('auto_check_updates');
  if (check == null) {
    prefs.setBool('auto_check_updates', false);
    check = false;
  }
  return check;
}
