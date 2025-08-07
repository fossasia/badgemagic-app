import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontPickerDialog extends StatelessWidget {
  final String? selectedFont;
  final ValueChanged<String?> onFontSelected;
  const FontPickerDialog(
      {super.key, required this.selectedFont, required this.onFontSelected});
  @override
  Widget build(BuildContext context) {
    final Map<String, String?> fontOptions = {
      'System Default': null,
      'Open Sans': 'Open Sans',
      'Oswald': 'Oswald',
      'Poppins': 'Poppins',
      'Lato': 'Lato',
      'Lexend': 'Lexend',
      'Public Sans': 'Public Sans',
      'Sora ': 'Sora',
    };
    return AlertDialog(
      title: Text('Select Font'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: fontOptions.length,
          itemBuilder: (context, index) {
            final displayName = fontOptions.keys.elementAt(index);
            final fontKey = fontOptions.values.elementAt(index);
            return RadioListTile<String?>(
              value: fontKey,
              groupValue: selectedFont,
              onChanged: (val) {
                onFontSelected(val);
              },
              title: fontKey == null
                  ? Text(displayName)
                  : Text(displayName, style: GoogleFonts.getFont(fontKey)),
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel')),
      ],
    );
  }
}
