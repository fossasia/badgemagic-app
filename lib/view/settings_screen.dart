import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/main.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../others/byte_array_utils.dart';
import '../others/globals.dart';
import '../others/localization_service.dart';
import '../providers/badge_scan_provider.dart';
import '../providers/firmware_update.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage = 'en';
  final List<String> languages = ['en', 'hi', 'it', 'ru'];

  late BadgeScanMode _scanMode;
  late List<TextEditingController> _controllers;
  late SharedPreferences prefs;
  bool autoCheck = false;
  bool _initialized = false;
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  final WchUsbIspFlasher _flasher = WchUsbIspFlasher();

  bool _isCheckingUpdate = false;
  Map<String, dynamic>? _availableUpdate;
  String? _updateStatusMessage;

  bool _isFlashingFirmware = false;
  String _flashStatusText = '';

  @override
  void initState() {
    super.initState();
    _setOrientation();
    initAutocheckFirmwareUpdate();
  }

  void initAutocheckFirmwareUpdate() async {
    prefs = await SharedPreferences.getInstance();
    bool checkResult = await autocheckFirmwareUpdates();
    if (mounted) {
      setState(() {
        autoCheck = checkResult;
      });
    }
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _handleManualUpdateCheck() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = null;
      _availableUpdate = null;
    });

    final updateInfo = await _flasher.checkForUpdates();

    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        if (updateInfo != null) {
          _availableUpdate = updateInfo;
        } else {
          _updateStatusMessage = l10n.alreadyUpdatedStatusMessage;
        }
      });
    }
  }

  Future<void> _handleStartUsbFirmwareUpdate() async {
    if (_availableUpdate == null) return;
    await _showFlashInstructionsDialog();
  }

  Future<void> _showFlashInstructionsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.integration_instructions_outlined,
                  color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.flashUsbConfirmationTitle),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(l10n.flashUsbInstructions),
                const SizedBox(height: 16),
                Text(
                  l10n.batteryDesolderedWarning,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final url = Uri.parse(
                        'https://github.com/fossasia/badgemagic-firmware');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text(
                    l10n.batteryDesolderedLink,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.doneButton),
              onPressed: () {
                Navigator.of(context).pop();
                _performUsbFirmwareUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performUsbFirmwareUpdate() async {
    setState(() {
      _isFlashingFirmware = true;
      _flashStatusText = l10n.firmwareDownloadProgress;
    });

    try {
      final List<dynamic> assets = _availableUpdate!['assets'] ?? [];
      final Uint8List firmwareData =
          await _flasher.downloadFirmwareBinary(assets);

      if (mounted) {
        setState(() {
          _flashStatusText = l10n.writingOnUsbIsp;
        });
      }

      if (Platform.isAndroid) {
        await _flasher.flashMergedBinary(
          firmwareData: firmwareData,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _flashStatusText =
                    l10n.flashUsbProgress((progress * 100).toStringAsFixed(0));
              });
            }
          },
        );
      } else if (Platform.isLinux) {
        await _flasher.flashMergedBinaryLinux(
            firmwareData: firmwareData,
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _flashStatusText = l10n
                      .flashUsbProgress((progress * 100).toStringAsFixed(0));
                });
              }
            });
      }

      if (mounted) {
        setState(() => _availableUpdate = null);
      }
    } catch (e) {
      logger.e('Flash USB error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFlashingFirmware = false;
          _flashStatusText = '';
        });
      }
    }
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
                Text(
                  l10n.language,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: Localizations.localeOf(context).languageCode,
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'hi', child: Text(l10n.hindi)),
                    DropdownMenuItem(value: 'it', child: Text(l10n.italian)),
                    DropdownMenuItem(value: 'ru', child: Text(l10n.russian)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedLanguage = value);
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
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  l10n.badgeScanMode,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                              label: Text(l10n.removeWithCount(
                                  provider.selectedIndices.length.toString())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorError,
                                foregroundColor: colorOnPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    final isSelected = provider.isSelected(index);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? colorSelected : colorBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? colorSelectedSurface
                            : colorTransparent,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) =>
                                provider.toggleSelection(index),
                            activeColor: colorSelected,
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
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (value) =>
                                    provider.updateBadgeName(index, value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _controllers.add(TextEditingController());
                      provider.addBadgeName('');
                    }),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMore),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  l10n.firmwareUpdate,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          _isCheckingUpdate ? null : _handleManualUpdateCheck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: indicatorColor,
                        elevation: 0,
                      ),
                      icon: _isCheckingUpdate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(l10n.checkFirmwareUpdateButton),
                    ),
                  ],
                ),
                if (_updateStatusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _updateStatusMessage!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
                if (_availableUpdate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.new_releases_sharp,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              l10n.newFirmwareVersionFound,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.versionLabel(_availableUpdate!['version']),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(l10n.releasedLabel(_availableUpdate!['date']),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (_isFlashingFirmware) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(
                            color: Colors.red,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _flashStatusText,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    setState(() => _availableUpdate = null),
                                child: Text(
                                  l10n.dismissButton,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (Platform.isAndroid || Platform.isLinux) ...[
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.usb, size: 18),
                                  onPressed: _handleStartUsbFirmwareUpdate,
                                  label: Text(l10n.flashViaUsb),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.usb, size: 18),
                                  onPressed: () => openUrl(
                                      'https://github.com/fossasia/badgemagic-firmware'),
                                  label: Text("See instructions on GitHub"),
                                ),
                              ],
                            ],
                          )
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(l10n.checkUpdateStartup),
                    Checkbox(
                      activeColor: colorPrimary,
                      value: autoCheck,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => autoCheck = value);
                        await prefs.setBool('auto_check_updates', value);
                      },
                    ),
                  ],
                ),
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
                        style: const TextStyle(color: colorOnSurface),
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
}
