import 'package:logger/logger.dart';

final Logger logger = Logger();

String toHex(List<int> bytes) {
  StringBuffer buffer = StringBuffer();
  for (int byte in bytes) {
    buffer.write('${byte < 16 ? '0' : ''}${byte.toRadixString(16)}');
  }
  return buffer.toString().toUpperCase();
}

bool isValidHex(String input) {
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(input);
}

List<int> hexStringToByteArray(String hexString) {
  if (hexString.length % 2 != 0 || !isValidHex(hexString)) {
    throw ArgumentError("Invalid hex string: $hexString");
  }

  List<int> data = [];
  for (int i = 0; i < hexString.length; i += 2) {
    int firstDigit = int.parse(hexString[i], radix: 16);
    int secondDigit = int.parse(hexString[i + 1], radix: 16);
    data.add((firstDigit << 4) + secondDigit);
  }

  return data;
}

List<List<bool>> hexStringToBool(String hexString) {
  int rows = 11;
  if (hexString.length % 2 != 0 || !isValidHex(hexString)) {
    throw ArgumentError("Invalid hex string: $hexString");
  }

  List<List<bool>> boolArray = List.generate(rows, (_) => []);
  int rowIndex = 0;

  for (int i = 0; i < hexString.length; i += 2) {
    // Convert the hex string into a byte (int)
    int byte = int.parse(hexString.substring(i, i + 2), radix: 16);

    // Convert the byte into a binary representation and then into booleans
    for (int bit = 7; bit >= 0; bit--) {
      boolArray[rowIndex].add(((byte >> bit) & 1) == 1);
    }

    // Move to the next row after filling current one
    rowIndex = (rowIndex + 1) % rows;
  }

  return boolArray;
}

List<List<int>> byteArrayToBinaryArray(List<int> byteArray) {
  List<List<int>> binaryArray = List.generate(11, (_) => []);

  int rowIndex = 0;
  for (int byte in byteArray) {
    List<int> binaryRepresentation = [];
    for (int i = 7; i >= 0; i--) {
      binaryRepresentation.add((byte >> i) & 1);
    }

    binaryArray[rowIndex].addAll(binaryRepresentation);

    rowIndex = (rowIndex + 1) % 11;
  }

  logger.d(
      "binaryArray: $binaryArray"); // Use print instead of logger for standalone example
  return binaryArray;
}

String hexToBin(String hex) {
  // Convert hex to binary string
  String binaryString = BigInt.parse(hex, radix: 16).toRadixString(2);

  // Pad the binary string with leading zeros if necessary to ensure it's a multiple of 8 bits
  int paddingLength = (8 - (binaryString.length % 8)) % 8;
  binaryString = binaryString.padLeft(binaryString.length + paddingLength, '0');
  logger.d("binaryString: $binaryString");
  return binaryString;
}

List<List<int>> binaryStringTo2DList(String binaryString) {
  int maxHeight = 11;
  List<List<int>> binary2DList = List.generate(maxHeight, (_) => []);

  for (int x = 0; x < binaryString.length; x++) {
    int a = 0;
    for (int y = a; y < 11; y++) {
      for (int z = 0; z < 8; z++) {
        binary2DList[y].add(int.parse(binaryString[x++]));
        if (x >= binaryString.length) {
          break;
        }
      }
      if (x >= binaryString.length) {
        break;
      }
    }
  }
  logger.d("binary2DList: $binary2DList");
  return binary2DList;
}
