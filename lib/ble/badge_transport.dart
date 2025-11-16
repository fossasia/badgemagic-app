import 'dart:typed_data';

abstract class BadgeTransport {
  Future<void> send(Uint8List data);
}

//This file is created to test the stream feature (in settings page) without the help of hardware device