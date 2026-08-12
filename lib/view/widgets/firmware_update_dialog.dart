import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_ble/universal_ble.dart';
import '../../badgemagic_module/utils/toast_utils.dart';
import '../../providers/BadgeScanProvider.dart';
import '../../services/firmware_update.dart';
import '../../services/localization_service.dart';

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
            nav.pop(); // Chiude la dialog iniziale

            // 1. Scansione per cercare la targhetta nelle vicinanze
            final device = await widget.service.scanForBadge(
              mode: BadgeScanMode.any, // Oppure la modalità preferita
              allowedNames: [],
            );

            if (device == null) {
              ToastUtils().showToast("Nessuna targhetta trovata nelle vicinanze.");
              return;
            }

            // 2. Connessione al dispositivo
            await UniversalBle.connect(device.deviceId);

            // 3. Esecuzione dell'aggiornamento con i parametri nominali richiesti
            await widget.service.executeFirmwareUpdate(
              deviceId: device.deviceId,
              releaseAssets: widget.releaseAssets,
              hardwareVariant: 'usbc_4key', // O variante dinamica
              onProgress: (progress) {
                // Opzionale: aggiorna una barra di caricamento
              },
            );
          },
          child: Text(l10n.updateButton),
        ),
      ],
    );
  }
}
