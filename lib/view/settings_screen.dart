import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import '../bademagic_module/utils/locale_persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(Locale)? onLocaleChange;
  const SettingsScreen({super.key, this.onLocaleChange});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage =
      'ENGLISH'; // Default, consider loading from user prefs if needed
  String selectedBadge = 'LSLED';

  final List<String> languages = ['ENGLISH', 'CHINESE', 'ESPANOL'];
  final Map<String, Locale> languageLocales = {
    'ENGLISH': Locale('en'),
    'CHINESE': Locale('zh'),
    'ESPANOL': Locale('es'),
  };
  final List<String> badges = ['LSLED', 'VBLAB'];

  @override
  void initState() {
    _setOrientation();
    _loadSavedLocale();
    super.initState();
  }

  void _loadSavedLocale() async {
    Locale? saved = await LocalePersistence.loadLocale();
    if (saved != null) {
      final entry = languageLocales.entries.firstWhere(
        (e) => e.value.languageCode == saved.languageCode,
        orElse: () => const MapEntry('ENGLISH', Locale('en')),
      );
      setState(() {
        selectedLanguage = entry.key;
      });
      if (widget.onLocaleChange != null) {
        widget.onLocaleChange!(entry.value);
      }
    }
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      index: 4,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.language ?? 'Language',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: mdGrey400),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLanguage = newValue!;
                    });
                    LocalePersistence.saveLocale(languageLocales[newValue!]!);
                    if (widget.onLocaleChange != null) {
                      widget.onLocaleChange!(languageLocales[newValue]!);
                    }
                  },
                  items:
                      languages.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)?.selectBadge ?? 'Select Badge',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBadge,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: mdGrey400),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBadge = newValue!;
                    });
                  },
                  items: badges.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      title: AppLocalizations.of(context)?.appTitle ?? 'Badge Magic',
    );
  }
}
