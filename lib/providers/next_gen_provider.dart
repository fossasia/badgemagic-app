class NgCommand {
  // 0x01 - power_setting
  static List<int> powerOff() => [0x01, 0x02];
  static List<int> setAutoResetAfterUpload(bool enabled) =>
      [0x01, 0x01, enabled ? 0x00 : 0x01];

  // 0x02 - streaming_setting
  static List<int> enterStreaming() => [0x02, 0x00];
  static List<int> leaveStreaming() => [0x02, 0x01];

  // 0x03 - stream_bitmap (word 16-bit per column, LSB = high pixel) <- this method is slow
  static List<int> streamBitmap(List<int> columnWords) {
    final bytes = <int>[0x03];
    for (final w in columnWords) {
      bytes.add(w & 0xFF); // LSB
      bytes.add((w >> 8) & 0xFF); // MSB
    }
    return bytes;
  }

  // 0x04 - ble_setting
  static List<int> setAlwaysOnBle(bool enabled) =>
      [0x04, 0x00, enabled ? 0x01 : 0x00];
  static List<int> setBleName(String name) {
    assert(name.length <= 20);
    return [0x04, 0x01, ...name.codeUnits];
  }

  // 0x05 - flash_splash_screen (xbm)
  static List<int> flashSplashScreen({
    required int width,
    required int height,
    required int frameHeight,
    required List<int> xbmData,
  }) =>
      [0x05, width, height, frameHeight, ...xbmData];

  // 0x06 - save_cfg
  static List<int> saveCfg() => [0x06];

  // 0x07 - load_fallback_cfg
  static List<int> loadFallbackCfg() => [0x07];

  // 0x08 - misc
  static List<int> setSplashSpeed(int speedMs) => [
        0x08,
        0x00,
        speedMs & 0xFF,
        (speedMs >> 8) & 0xFF,
      ];
  static List<int> setBrightness(int level) => [0x08, 0x01, level];
}
