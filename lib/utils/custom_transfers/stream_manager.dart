import 'dart:async';
import 'dart:typed_data';

class StreamManager {
  final _controller = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get frameStream => _controller.stream;

  bool enabled = false;

  void enable() {
    enabled = true;
  }

  void disable() {
    enabled = false;
  }

  void sendFrame(Uint8List frameBytes) {
    if (!enabled) return;
    _controller.add(frameBytes);
  }

  void dispose() {
    _controller.close();
  }
}
