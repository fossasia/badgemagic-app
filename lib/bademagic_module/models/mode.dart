enum Mode {
  left('0x00'),
  right('0x01'),
  up('0x02'),
  down('0x03'),
  fixed('0x04'),
  snowflake('0x05'),
  picture('0x06'),
  animation('0x07'),
  laser('0x08');

  final String hexValue;
  const Mode(this.hexValue);

  //method to get the integer value of the mode
  static int getIntValue(Mode mode) {
    String hexValue = mode.hexValue.substring(3, 4);
    int intValue = int.parse(hexValue, radix: 10);
    return intValue;
  }

  // Helper method to safely parse hex value
  static Mode fromHex(String hexValue) {
    return Mode.values.firstWhere(
      (mode) => mode.hexValue == hexValue,
      orElse: () => Mode.left, // Default to Mode.left if no match
    );
  }
}
