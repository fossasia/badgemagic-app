enum Speed {
  one('0x00'),
  two('0x10'),
  three('0x20'),
  four('0x30'),
  five('0x40'),
  six('0x50'),
  seven('0x60'),
  eight('0x70');

  final String hexValue;
  const Speed(this.hexValue);

  static int getIntValue(Speed speed) {
    return speed.index + 1;
  }

  static Speed fromHex(String hexValue) {
    return Speed.values.firstWhere(
      (speed) => speed.hexValue == hexValue,
      orElse: () => Speed.one,
    );
  }
}
