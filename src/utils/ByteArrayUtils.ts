export const ByteArrayUtils = {
  hexStringToByteArray(hexString: string): Uint8Array {
    const length = hexString.length;
    const data = new Uint8Array(length / 2);
    for (let i = 0; i < length; i += 2) {
      const firstDigit = hexString[i];
      const secondDigit = hexString[i + 1];
      if (firstDigit && secondDigit)
        data[i / 2] =
          (ByteArrayUtils.getCharacterDigit(firstDigit, 16) << 4) +
          ByteArrayUtils.getCharacterDigit(secondDigit, 16);
    }
    return data;
  },

  getCharacterDigit(hexChar: string, radix: number): number {
    return parseInt(hexChar, radix);
  },

  byteArrayToHexString(byteArray: Uint8Array): string {
    let result = '';
    for (const b of byteArray) {
      result += ByteArrayUtils.formatStringToHex(b);
    }
    return result;
  },

  formatStringToHex(byte: number): string {
    return ('0' + (byte & 0xff).toString(16)).slice(-2);
  },
};
