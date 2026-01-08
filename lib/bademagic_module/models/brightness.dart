enum Brightness {
  twentyFive('0x30', 25),
  fifty('0x20', 50),
  seventyFive('0x10', 75),
  hundred('0x00', 100);

  final String hexValue;
  final int percentage;
  const Brightness(this.hexValue, this.percentage);

  // Static method to get int value (percentage) from the Enum Brightness
  static int getIntValue(Brightness brightness) {
    return brightness.percentage;
  }

  // Static method to get Brightness from hex value
  static Brightness fromHex(String hexValue) {
    return Brightness.values.firstWhere(
      (brightness) => brightness.hexValue == hexValue,
      orElse: () => Brightness.hundred, // Default to 100%
    );
  }

  // Static method to get Brightness from percentage value
  static Brightness fromPercentage(int percentage) {
    if (percentage <= 25) {
      return Brightness.twentyFive;
    } else if (percentage <= 50) {
      return Brightness.fifty;
    } else if (percentage <= 75) {
      return Brightness.seventyFive;
    } else {
      return Brightness.hundred;
    }
  }
}
