import 'dart:async';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/communication/write_state.dart';
import 'package:badgemagic/communication/completed_state.dart';
import 'package:badgemagic/view/widgets/auth_pin_data.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/others/app_logger.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';
import 'package:universal_ble/universal_ble.dart';
import 'base_ble_state.dart';

class ConnectState extends RetryBleState {
  final BleDevice scanResult;
  final DataTransferManager manager;
  final BuildContext context;
  final bleDialogController = GetIt.instance<BleDialogController>();
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  ConnectState({
    required this.manager,
    required this.scanResult,
    required this.context,
  });

  @override
  Future<BleState?> processState() async {
    final deviceId = scanResult.deviceId;
    try {
      try {
        await UniversalBle.disconnect(deviceId);
        logger.d("Pre-emptive disconnect for clean state");
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {
        logger.d("No existing connection to disconnect");
      }

      await UniversalBle.connect(deviceId);

      final connectionState = await UniversalBle.getConnectionState(deviceId);

      if (connectionState != BleConnectionState.connected) {
        throw Exception("Failed to connect to the device");
      }

      logger.d("Device connected successfully");
      bleDialogController.update(
          BleDialogStatus.connecting, l10n.connectionSucceeded);
      manager.connectedDevice = scanResult;

      if (manager is RawDataTransferManager) {
        final rawManager = manager as RawDataTransferManager;
        if (rawManager.pin.isEmpty) {
          if (!context.mounted) {
            throw Exception("Context no longer valid for PIN dialog");
          }
          final enteredPin = await showPinAuthDialog(context);
          if (enteredPin == null) {
            rawManager.cancelledByUser = true;
            return CompletedState(
              isSuccess: false,
              message: l10n.transferCanceledByUser,
            );
          }
          rawManager.pin = enteredPin;
        }
      }

      final writeState = WriteState(
        device: scanResult,
        manager: manager,
      );
      return await writeState.process();
    } catch (e) {
      bleDialogController.update(BleDialogStatus.error, l10n.connexionFailed);
      rethrow;
    }
  }

  static Future<void> stopAllBleOperations() async {
    WriteState.cancelTransfer();
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
  }
}
