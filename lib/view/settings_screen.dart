import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage = 'en';
  String _selectedBadge = 'LSLED';
  final List<String> _badges = ['LSLED', 'VBLAB'];

  // Localized badge names
  final Map<String, String> _localizedBadgeNames = {
    'LSLED': 'LSLED',
    'VBLAB': 'VBLAB',
  };

  @override
  void initState() {
    super.initState();
    // Initialize with current locale if available
    final currentLocale = WidgetsBinding.instance.window.locale;
    if (currentLocale.languageCode == 'hi') {
      _selectedLanguage = 'hi';
    } else {
      _selectedLanguage = 'en'; // Default to English
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selection
            Text(
              AppLocalizations.of(context)!.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(AppLocalizations.of(context)!.english),
                ),
                DropdownMenuItem(
                  value: 'hi',
                  child: Text(AppLocalizations.of(context)!.hindi),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  // Update app locale and save preference
                  final newLocale = Locale(value);
                  appLocale.value = newLocale;
                  // Save the selected language
                  LanguageService.setLanguage(value);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),

            const SizedBox(height: 24),

            // Badge Selection
            Text(
              AppLocalizations.of(context)!.selectBadge,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBadge,
              items: _badges.map((badge) {
                return DropdownMenuItem(
                  value: badge,
                  child: Text(_localizedBadgeNames[badge] ?? badge),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBadge = value;
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
