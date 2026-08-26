import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../others/byte_array_utils.dart';
import '../../others/globals.dart';
import '../../others/localization_service.dart';
import '../../others/toast_utils.dart';
import '../../providers/firmware_update.dart';

class FirmwareUpdateDialog extends StatefulWidget {
  final String version;
  final String date;
  final List<dynamic> releaseAssets;

  const FirmwareUpdateDialog({
    super.key,
    required this.version,
    required this.date,
    required this.releaseAssets,
  });

  @override
  State<FirmwareUpdateDialog> createState() => _FirmwareUpdateDialogState();
}

class _FirmwareUpdateDialogState extends State<FirmwareUpdateDialog> {
  bool _dontRemindAgain = false;
  bool _isFlashing = false;
  double _flashProgress = 0.0;
  String _statusText = '';

  final WchUsbIspFlasher _flasher = WchUsbIspFlasher();

  Future<void> _skipVersionPermanently(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_firmware_version_$version', true);
  }

  Future<void> _startUsbFlash() async {
    setState(() {
      _isFlashing = true;
      _flashProgress = 0.0;
      _statusText = 'Download del firmware in corso...';
    });

    try {
      if (_dontRemindAgain) {
        await _skipVersionPermanently(widget.version);
      }

      // 1. Download del file merged.bin da GitHub
      final Uint8List firmwareData =
          await _flasher.downloadFirmwareBinary(widget.releaseAssets);

      if (mounted) {
        setState(() {
          _statusText = 'Connessione USB e scrittura Flash...';
        });
      }

      // 2. Scrittura via cavo USB Bootloader
      await _flasher.flashMergedBinary(
        firmwareData: firmwareData,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _flashProgress = progress;
              _statusText =
                  'Flash USB: ${(progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      ToastUtils().showToast('Firmware aggiornato con successo via USB!');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Errore flash USB: $e');
      ToastUtils().showToast('Errore: $e');
      if (mounted) {
        setState(() {
          _isFlashing = false;
          _statusText = '';
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
          Text('• Version: ${widget.version}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('• Date: ${widget.date}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Collega il badge con cavo OTG in modalità Bootloader (tieni premuto il pulsante mentre inserisci il cavo).',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          if (_isFlashing) ...[
            LinearProgressIndicator(
              value: _flashProgress,
              color: Colors.red,
              backgroundColor: Colors.red.shade100,
            ),
            const SizedBox(height: 6),
            Text(
              _statusText,
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.flash_on, size: 18),
            onPressed: _startUsbFlash,
            label: const Text('Flash via USB'),
          ),
        ],
      ],
    );
  }
}
