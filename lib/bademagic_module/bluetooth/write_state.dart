import 'dart:typed_data';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:universal_ble/universal_ble.dart';
import '../../globals/globals.dart';
import 'base_ble_state.dart';
import 'completed_state.dart';

class WriteState extends NormalBleState {
  final BleDevice device;
  final DataTransferManager manager;

  WriteState({required this.manager, required this.device});

  @override
  Future<BleState?> processState() async {
    List<List<int>> dataChunks = await manager.generateDataChunk();
    logger.d("Data to write: $dataChunks");

    final deviceId = device.deviceId;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await UniversalBle.discoverServices(deviceId);

      for (List<int> chunk in dataChunks) {
        bool success = false;

        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            await UniversalBle.write(deviceId, serviceUuid, characteristicUuid,
                Uint8List.fromList(chunk),
                withoutResponse: false);

            logger.d("Chunk written successfully: $chunk");
            success = true;
            break;
          } catch (e) {
            logger.e("Write failed (attempt $attempt/3): $e");
          }
        }

        if (!success) {
          throw Exception("Failed to transfer data. Please try again.");
        }

        await Future.delayed(const Duration(milliseconds: 120));
      }

      logger.d("Characteristic written successfully");
      return CompletedState(
          isSuccess: true, message: "Data transferred successfully");
    } catch (e) {
      logger.e("Failed to write characteristic: $e");
      throw Exception("Failed to transfer data. Please try again.");
    } finally {
      try {
        logger.d("Disconnecting from device after write attempt...");
        await UniversalBle.disconnect(deviceId);
        await Future.delayed(const Duration(milliseconds: 700));
        logger.d("Device disconnected and delay complete.");
      } catch (e) {
        logger.e("Error during disconnect: $e");
      }
    }
  }
}
