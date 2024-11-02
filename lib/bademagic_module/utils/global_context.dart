import 'package:flutter/material.dart';

class GlobalContextProvider {
  static final GlobalContextProvider _instance =
      GlobalContextProvider._internal();

  GlobalContextProvider._internal();

  static GlobalContextProvider get instance => _instance;

  BuildContext? _context;

  // Set the context
  void setContext(BuildContext context) {
    _context = context;
  }

  // Retrieve the context
  BuildContext? get context {
    if (_context == null) {
      throw FlutterError(
          "GlobalContextProvider: Context is not set. Ensure it's initialized in your app.");
    }
    return _context;
  }
}
