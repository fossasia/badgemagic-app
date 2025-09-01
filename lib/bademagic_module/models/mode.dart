enum Mode {
  left('0x00'),
  right('0x01'),
  up('0x02'),
  down('0x03'),
  fixed('0x04'),
  animation('0x05'),
  snowflake('0x06'),
  picture('0x07'),
  laser('0x08'),
  pacman('0x09'), // Added Pacman mode
  chevronleft('0x0A'), // Chevron left mode
  diamond('0x0B'), // Diamond animation mode
  feet('0x0C'), // Feet animation mode
  brokenhearts('0x0D'), // Broken Hearts animation mode
  cupid('0x0E'); // Cupid animation mode

  final String hexValue;
  const Mode(this.hexValue);

  static int getIntValue(Mode mode) {
    return int.parse(mode.hexValue.substring(2), radix: 16);
  }

  static Mode fromHex(String hexValue) {
    return Mode.values.firstWhere(
      (mode) => mode.hexValue == hexValue,
      orElse: () => Mode.left,
    );
  }

  static Mode fromInt(int value) {
    final hex = value.toRadixString(16).padLeft(2, '0');
    return fromHex('0x$hex');
  }
}
