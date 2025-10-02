import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';

/// Builds USB CDC payloads from Badge data.
/// Same format as BLE, but split into 64-byte chunks.
class PayloadBuilder {
  final DataTransferManager manager;

  PayloadBuilder({required this.manager});

  Future<List<List<int>>> buildPayloads() async {
    // Generate the raw payload using the existing BLE generator
    final rawChunks = await manager.generateDataChunk();

    // Flatten because BLE uses 16-byte chunks
    final flat = rawChunks.expand((c) => c).toList();

    // Split into 64-byte chunks for USB CDC
    final usbChunks = <List<int>>[];
    for (int i = 0; i < flat.length; i += 64) {
      usbChunks.add(
        flat.sublist(i, i + 64 > flat.length ? flat.length : i + 64),
      );
    }

    return usbChunks;
  }
}
