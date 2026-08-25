import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_ble/universal_ble.dart';
import '../../others/globals.dart';
import '../../others/localization_service.dart';
import '../../others/toast_utils.dart';
import '../../providers/badge_scan_provider.dart';
import '../../providers/firmware_update.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.red),
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
          const SizedBox(height: 20),
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
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_dontRemindAgain) {
              await widget.service.skipVersionPermanently(widget.version);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.laterButton),
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
    );
  }
}
