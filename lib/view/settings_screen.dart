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
                const Text('Badge Scan Mode',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<BadgeScanMode>(
                  title: const Text('Connect to any badge'),
                  value: BadgeScanMode.any,
                  groupValue: _scanMode,
                  onChanged: (value) => setState(() => _scanMode = value!),
                ),
                RadioListTile<BadgeScanMode>(
                  title:
                      const Text('Connect to badges with the following names'),
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
                                child: const Text('Select All'),
                              ),
                              TextButton(
                                onPressed: () => provider.clearSelection(),
                                child: const Text('Clear All'),
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
                                decoration: const InputDecoration(
                                  hintText: 'Badge name',
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
                    label: const Text('Add More'),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.setMode(_scanMode);
                    provider.setBadgeNames(
                      _controllers.map((c) => c.text.trim()).toList(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scan settings saved')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Save Settings"),
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
