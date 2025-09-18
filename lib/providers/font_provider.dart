import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontProvider extends ChangeNotifier {
  String? _selectedFont;
  final List<String> availableFonts = const [
    'Roboto',
    'Open Sans',
    'Lato',
    'Poppins',
    'Montserrat',
    'Orbitron',
    'Lexend',
  ];

  String? get selectedFont => _selectedFont;

  void changeFont(String? newFont) {
    _selectedFont = newFont;
    notifyListeners();
  }

  TextStyle get selectedTextStyle {
    const baseStyle = TextStyle(fontSize: 12, color: Colors.black);
    if (_selectedFont == null) return baseStyle;

    switch (_selectedFont!) {
      case 'Roboto':
        return GoogleFonts.roboto(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Open Sans':
        return GoogleFonts.openSans(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lato':
        return GoogleFonts.lato(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Poppins':
        return GoogleFonts.poppins(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w500));
      case 'Montserrat':
        return GoogleFonts.montserrat(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Orbitron':
        return GoogleFonts.orbitron(
            textStyle:
                baseStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w700));
      case 'Lexend':
        return GoogleFonts.lexend(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      default:
        return baseStyle;
    }
  }
}
