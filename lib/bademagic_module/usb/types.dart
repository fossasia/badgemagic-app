import 'dart:typed_data';
import 'dart:async';

abstract class AsyncDataSinkSource {
  Future<void> write(Uint8List data);
  Stream<Uint8List>? get inputStream;
}
