import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class for handling font-related operations in the badge app.
///
/// This class provides methods for font selection and style management.
/// It helps determine whether to use the system default font or a custom font,
/// and provides the appropriate TextStyle for rendering.
class FontUtils {
  /// Checks if the selected font is the system default.
  ///
  /// The system default font uses the original charCodes map from DataToByteArrayConverter
  /// for better compatibility with the badge's limited resolution.
  ///
  /// @param fontFamily The selected font family name, or null/empty for system default
  /// @return true if system default should be used (null or empty string), false otherwise
  static bool isSystemDefault(String? fontFamily) {
    return fontFamily == null || fontFamily.isEmpty;
  }

  /// Gets the appropriate TextStyle for the selected font.
  ///
  /// Returns null for system default font, which uses the original charCodes map.
  /// For custom fonts, returns a TextStyle using Google Fonts package.
  ///
  /// Note: Custom fonts may have reduced character support due to the badge's
  /// limited resolution (11x44 pixels) and may cause characters to be cut off.
  ///
  /// @param fontFamily The selected font family name
  /// @return TextStyle for custom fonts, or null for system default
  static TextStyle? getTextStyle(String? fontFamily) {
    if (isSystemDefault(fontFamily)) {
      return null;
    }
    return GoogleFonts.getFont(fontFamily!);
  }
}
