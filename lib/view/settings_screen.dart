import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:get_it/get_it.dart';
import '../../main.dart';

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
    // Initialize with current active app locale (fallback to 'en')
    _selectedLanguage = appLocale.value?.languageCode ?? 'en';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
            Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: Localizations.localeOf(context).languageCode,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.english),
                ),
                DropdownMenuItem(
                  value: 'hi',
                  child: Text(l10n.hindi),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  // Update app locale
                  final newLocale = Locale(value);
                  appLocale.value = newLocale;
                  // Persist via LocalizationService
                  GetIt.instance
                      .get<LocalizationService>()
                      .saveLocale(newLocale);
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
            Text(l10n.selectBadge,
                style: Theme.of(context).textTheme.titleMedium),
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
