import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage = 'en';
  final List<String> languages = ['en', 'hi'];

  late BadgeScanMode _scanMode;
  late List<TextEditingController> _controllers;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    if (_initialized) {
      for (final controller in _controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Consumer<BadgeScanProvider>(
      builder: (context, provider, child) {
        if (!provider.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Initialize controllers once after provider is loaded
        if (!_initialized) {
          _scanMode = provider.mode;
          _controllers = provider.badgeNames
              .map((name) => TextEditingController(text: name))
              .toList();
          _initialized = true;
        }

        return CommonScaffold(
          index: 4,
          title: l10n.settings,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(l10n.language,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
                        selectedLanguage = value;
                      });
                      final newLocale = Locale(value);
                      appLocale.value = newLocale;
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
                Text(l10n.badgeScanMode,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<BadgeScanMode>(
                  title: Text(l10n.connectToAnyBadge),
                  value: BadgeScanMode.any,
                  groupValue: _scanMode,
                  onChanged: (value) => setState(() => _scanMode = value!),
                ),
                RadioListTile<BadgeScanMode>(
                  title: Text(l10n.connectToBadgesWithNames),
                  value: BadgeScanMode.specific,
                  groupValue: _scanMode,
                  onChanged: (value) => setState(() => _scanMode = value!),
                ),
                if (_scanMode == BadgeScanMode.specific) ...[
                  // Selection controls row
                  if (_controllers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => provider.selectAll(),
                                child: Text(l10n.selectAll),
                              ),
                              TextButton(
                                onPressed: () => provider.clearSelection(),
                                child: Text(l10n.clearAll),
                              ),
                            ],
                          ),
                          if (provider.selectedIndices.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                provider.removeSelectedDevices();
                                // Update controllers after removal
                                setState(() {
                                  for (final controller in _controllers) {
                                    controller.dispose();
                                  }
                                  _controllers = provider.badgeNames
                                      .map((name) =>
                                          TextEditingController(text: name))
                                      .toList();
                                });
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: Text(
                                  'Remove (${provider.selectedIndices.length})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Badge name list with checkboxes
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    final isSelected = provider.isSelected(index);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Colors.blue.shade50
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) =>
                                provider.toggleSelection(index),
                            activeColor: Colors.blue,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: l10n.badgeNameHint,
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (value) {
                                  // Update the provider when text changes
                                  provider.updateBadgeName(index, value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Add more button
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _controllers.add(TextEditingController());
                      provider.addBadgeName(''); // Add empty badge name
                    }),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMore),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      provider.setMode(_scanMode);
                      provider.setBadgeNames(
                        _controllers.map((c) => c.text.trim()).toList(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.scanSettingsSaved)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: mdGrey400,
                      ),
                      child: Text(
                        l10n.saveSettings,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

//   Widget _buildDropdown({
//     required String selectedValue,
//     required List<String> values,
//     required Function(String) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: selectedValue,
//           isExpanded: true,
//           icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           onChanged: (String? newValue) {
//             if (newValue != null) onChanged(newValue);
//           },
//           items: values.map<DropdownMenuItem<String>>((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value, style: const TextStyle(color: Colors.black)),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
}
