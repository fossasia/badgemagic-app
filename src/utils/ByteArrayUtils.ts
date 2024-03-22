export class ByteArrayUtils {
  static hexStringToByteArray(hexString: string) {
    const length = hexString.length;
    const data = new Uint8Array(length / 2);

    for (let i = 0; i < length; i += 2) {
      data[i / 2] =
        (ByteArrayUtils.getCharacterDigit(hexString[i], 16) << 4) +
        ByteArrayUtils.getCharacterDigit(hexString[i + 1], 16);
    }
    return data;
  }

  static getCharacterDigit(hexChar: string, radix: number) {
    return parseInt(hexChar, radix);
  }

  static byteArrayToHexString(byteArray: Uint8Array) {
    let result = "";
    for (const b of byteArray) {
      result += ByteArrayUtils.formatStringToHex(b);
    }
    return result;
  }

  static formatStringToHex(byte: number) {
    return ("0" + (byte & 0xff).toString(16)).slice(-2);
  }
}
