import 'dart:async';
import 'dart:typed_data';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:get_it/get_it.dart';
import '../../services/localization_service.dart';
import '../../view/widgets/ble_progress_dialog.dart';
import '../../view/widgets/ble_progress_dialog_controller.dart';
import 'package:universal_ble/universal_ble.dart';
import '../../globals/globals.dart';
import 'base_ble_state.dart';
import 'completed_state.dart';

class WriteState extends NormalBleState {
  final BleDevice device;
  final DataTransferManager manager;
  final bleDialogController = GetIt.instance<BleDialogController>();
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  static bool isCancellationRequested = false;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 200);
  static const Duration _chunkDelay = Duration(milliseconds: 120);
  static const Duration _initialDelay = Duration(milliseconds: 300);
  static const Duration _disconnectTimeout = Duration(seconds: 2);
  static const Duration _postDisconnectDelay = Duration(milliseconds: 500);

  WriteState({required this.manager, required this.device});

  static Future<void> cancelTransfer() async {
    isCancellationRequested = true;
    await Future.delayed(const Duration(seconds: 1));
    isCancellationRequested = false;
  }

  BleState? _handleAbortedState() {
    return CompletedState(
      isSuccess: false,
      message: l10n.transferAborted,
    );
  }

  @override
  Future<BleState?> processState() async {
    final List<List<int>> dataChunks = await manager.generateDataChunk();
    logger.d("Data to write: $dataChunks");

    final String deviceId = device.deviceId;
    final int totalChunks = dataChunks.length;
    int currentChunkIndex = 0;

    double displayedProgress = 0.0;
    double targetProgress = 0.0;
    const double smoothingStep = 0.01;
    const Duration tickInterval = Duration(milliseconds: 16);

    final Timer progressTimer = Timer.periodic(tickInterval, (_) {
      if (displayedProgress < targetProgress) {
        displayedProgress =
            (displayedProgress + smoothingStep).clamp(0.0, targetProgress);

        final int displayedPercent = (displayedProgress * 100).round();

        bleDialogController.update(
          BleDialogStatus.transferring,
          "Sending data...\n$displayedPercent%",
          newProgress: displayedProgress,
        );
      }
    });

    try {
      await Future.delayed(_initialDelay);
      if (isCancellationRequested) return _handleAbortedState();

      final services = await UniversalBle.discoverServices(deviceId);
      final serviceExists = services.any((s) => s.uuid == serviceUuid);
      if (!serviceExists) {
        throw Exception(l10n.noBLEServiceFound);
      }

      for (final List<int> chunk in dataChunks) {
        if (isCancellationRequested) {
          return _handleAbortedState();
        }

        currentChunkIndex++;
        targetProgress = currentChunkIndex / totalChunks;

        await _writeChunkWithRetry(
          deviceId: deviceId,
          chunk: chunk,
          chunkIndex: currentChunkIndex,
          totalChunks: totalChunks,
        );

        await Future.delayed(_chunkDelay);
      }
      targetProgress = 1.0;
      await Future.delayed(const Duration(milliseconds: 300));

      logger.d("All chunks written successfully");

      if (isCancellationRequested) return _handleAbortedState();

      return CompletedState(
        isSuccess: true,
        message: l10n.transferSucceeded,
      );
    } catch (e) {
      logger.e("Transfer failed: $e");
      if (!isCancellationRequested) {
        bleDialogController.update(
          BleDialogStatus.error,
          l10n.transferFailed,
        );
      }
      rethrow;
    } finally {
      progressTimer.cancel();
      await _safeDisconnect(deviceId);
    }
  }

  Future<void> _writeChunkWithRetry({
    required String deviceId,
    required List<int> chunk,
    required int chunkIndex,
    required int totalChunks,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      if (isCancellationRequested) return;
      try {
        await UniversalBle.write(
          deviceId,
          serviceUuid,
          characteristicUuid,
          Uint8List.fromList(chunk),
          withoutResponse: false,
        );
        logger.d("Chunk $chunkIndex written successfully on attempt $attempt");
        return;
      } catch (e) {
        final errorStr = e.toString();
        final isHardDisconnection = errorStr.contains('DEVICE_DISCONNECTED') ||
            errorStr.contains('DEVICE_NOT_FOUND') ||
            errorStr.contains('deviceDisconnected') ||
            errorStr.contains('deviceNotFound');

        if (isHardDisconnection) {
          final isNearEnd = chunkIndex >= (totalChunks * 0.85).floor();

          if (isNearEnd) {
            logger.w(
              "Chunk $chunkIndex/$totalChunks: device disconnected near end — "
              "treating as implicit success.",
            );
            return;
          } else {
            logger.e(
              "Chunk $chunkIndex/$totalChunks: device disconnected too early — aborting retries.",
            );
            break;
          }
        }

        logger.e(
            "Chunk $chunkIndex write failed (attempt $attempt/$_maxRetries): $e");
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }
    throw Exception(l10n.transferFailed);
  }

  Future<void> _safeDisconnect(String deviceId) async {
    try {
      logger.d("Disconnecting from device...");

      await UniversalBle.disconnect(deviceId).timeout(_disconnectTimeout);

      await Future.delayed(_postDisconnectDelay);
      logger.d("Device disconnected successfully.");
    } catch (e) {
      logger.w("Disconnect warning (non-critical): $e");
    }
  }
}
