import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../others/globals.dart';
import '../../others/localization_service.dart';
import '../../others/toast_utils.dart';
import '../../providers/badge_scan_provider.dart';
import '../../providers/firmware_update.dart';
import '../../providers/firmware_update_ble.dart';

class FirmwareUpdateDialog extends StatefulWidget {
  final String version;
  final String date;
  final List<dynamic> releaseAssets;
  final FirmwareUpdateService service;

  const FirmwareUpdateDialog({
    super.key,
    required this.version,
    required this.date,
    required this.releaseAssets,
    required this.service,
  });

  @override
  State<FirmwareUpdateDialog> createState() => _FirmwareUpdateDialogState();
}

class _FirmwareUpdateDialogState extends State<FirmwareUpdateDialog> {
  bool _dontRemindAgain = false;
  bool _isFlashing = false;
  String _flashStatusText = '';

  final WchUsbIspFlasher _flasher = WchUsbIspFlasher();

  Future<void> _skipVersionPermanently(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_firmware_version_$version', true);
  }

  Future<void> _startUsbFlash() async {
    await _showFlashInstructionsDialog();
  }

  Future<BleDevice?> scanForBadge({
    required BadgeScanMode mode,
    required List<String> allowedNames,
  }) async {
    final completer = Completer<BleDevice?>();
    StreamSubscription<BleDevice>? subscription;

    final normalizedNames = allowedNames
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    subscription = UniversalBle.scanStream.listen((device) async {
      final matchesUuid = device.services.contains(serviceUuid);
      final deviceName = (device.name ?? "").trim().toLowerCase();
      final matchesName =
          mode == BadgeScanMode.any || normalizedNames.contains(deviceName);

      if (matchesUuid && matchesName) {
        subscription?.cancel();
        await UniversalBle.stopScan();
        if (!completer.isCompleted) {
          completer.complete(device);
        }
      }
    });

    await UniversalBle.startScan(
      scanFilter: ScanFilter(withServices: [serviceUuid]),
    );

    Timer(const Duration(seconds: 10), () async {
      await UniversalBle.stopScan();
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<void> _showFlashInstructionsDialog() async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
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
                _performUsbFlash();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performUsbFlash() async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    setState(() {
      _isFlashing = true;
      _flashStatusText = l10n.firmwareDownloadProgress;
    });

    try {
      if (_dontRemindAgain) {
        await _skipVersionPermanently(widget.version);
      }

      final Uint8List firmwareData =
      await _flasher.downloadFirmwareBinary(widget.releaseAssets);

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

      ToastUtils().showToast(l10n.firmwareUpdateSuccess);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ToastUtils().showToast('Error: $e');
      if (mounted) {
        setState(() {
          _isFlashing = false;
          _flashStatusText = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.usb, color: Colors.red),
          const SizedBox(width: 10),
          Text(l10n.newFirmwareVersionFound),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.dialogNewFirmwareVersionFound}\n'),
          Text(l10n.versionLabel(widget.version),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(l10n.releasedLabel(widget.date),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isFlashing) ...[
            LinearProgressIndicator(
              color: Colors.red,
              backgroundColor: Colors.red.shade100,
            ),
            const SizedBox(height: 6),
            Text(
              _flashStatusText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ] else ...[
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    activeColor: Colors.red,
                    value: _dontRemindAgain,
                    onChanged: (bool? value) {
                      setState(() {
                        _dontRemindAgain = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.dontRememberFirmwareVersionUpdate,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (!_isFlashing) ...[
          TextButton(
            onPressed: () async {
              if (_dontRemindAgain) {
                await _skipVersionPermanently(widget.version);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.laterButton),
          ),
          if (Platform.isAndroid || Platform.isLinux)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.usb, size: 18),
              onPressed: _startUsbFlash,
              label: Text(l10n.flashViaUsb),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (_dontRemindAgain) {
                await widget.service.skipVersionPermanently(widget.version);
              }

              final nav = Navigator.of(context);
              nav.pop();

              final device = await scanForBadge(
                mode: BadgeScanMode.any,
                allowedNames: [],
              );

              if (device == null) {
                ToastUtils().showToast(l10n.noBadgesFound);
                return;
              }

              await UniversalBle.connect(device.deviceId);

              await widget.service.executeFirmwareUpdate(
                deviceId: device.deviceId,
                releaseAssets: widget.releaseAssets,
                hardwareVariant: 'usbc_4key',
                onProgress: (progress) {},
              );
            },
            child: Text(l10n.updateButton),
          ),
        ],
      ],
    );
  }
}