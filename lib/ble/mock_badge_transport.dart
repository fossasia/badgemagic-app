import 'dart:typed_data';
import 'badge_transport.dart';
import 'package:flutter/foundation.dart';

class MockBadgeTransport implements BadgeTransport {
  int _frameCount = 0;

  @override
  Future<void> send(Uint8List data) async {
    _frameCount++;

    debugPrint(
      '[STREAM MOCK] frame=$_frameCount bytes=${data.length}',
    );

    await Future.delayed(const Duration(milliseconds: 20));
  }
}

//This file is created to test the stream feature (in settings page) without the help of hardware device
