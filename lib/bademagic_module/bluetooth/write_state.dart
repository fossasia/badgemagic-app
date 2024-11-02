import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';
import 'completed_state.dart';

class WriteState extends NormalBleState {
  final BluetoothDevice device;
  final DataTransferManager manager;

  WriteState({required this.manager, required this.device});

  @override
  Future<BleState?> processState() async {
    List<List<int>> dataChunks = await manager.generateDataChunk();
    logger.d("Data to write: $dataChunks");

    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid ==
                  Guid("0000fee1-0000-1000-8000-00805f9b34fb") &&
              characteristic.properties.write) {
            for (List<int> chunk in dataChunks) {
              bool success = false;
              for (int attempt = 1; attempt <= 3; attempt++) {
                try {
                  await characteristic.write(chunk, withoutResponse: false);
                  success = true;
                  break;
                } catch (e) {
                  logger.e("Write failed, retrying ($attempt/3): $e");
                }
              }
              if (!success) {
                throw Exception("Failed to transfer data. Please try again.");
              }
            }
            logger.d("Characteristic written successfully");
            return CompletedState(
                isSuccess: true, message: "Data transferred successfully");
          }
        }
      }
      throw Exception("Please use the correct Badge");
    } catch (e) {
      logger.e("Failed to write characteristic: $e");
      throw Exception("Failed to transfer data. Please try again.");
    }
  }
}
