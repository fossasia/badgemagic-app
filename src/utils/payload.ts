import Base64 from 'base64-js';

import {type BadgeConfigFormData} from '@/models/BadgeForm.model';

import {ByteArrayUtils} from './ByteArrayUtils';
import {ALLOWED_CHARACTERS, LETTERS_HEX_BITMAPS, type SupportedLetter} from './constants';

const HEADER = '77616E670000';

// const SIZES =
//   "0001" + "0000" + "0000" + "0000" + "0000" + "0000" + "0000" + "0000";

const PADDING1 = '000000000000';

// const TIMESTAMP = "E803160D2610";

const PADDING2 = '00000000';

const SEPARATOR = '00000000000000000000000000000000';

// export const PAYLOAD = "00386CC6C6FEC6C6C6C600";
export const PAYLOAD = '007CC6C6C0C0C0C6C67C00';

const PAYLOAD_SIZE_IN_BYTES = 16;

const BYTES_IN_ONE_HEX = 2;

const HEX_CHARACTERS_PER_CHUNK = PAYLOAD_SIZE_IN_BYTES * BYTES_IN_ONE_HEX;

const MAX_BITMAPS_NUMBER = 8;

// export const BADGE_PACKET =
//   HEADER +
//   FLASH +
//   MARQUEE +
//   MODES +
//   SIZES +
//   PADDING1 +
//   TIMESTAMP +
//   PADDING2 +
//   SEPARATOR +
//   PAYLOAD +
//   PADDING3;

export function getPackets(data: BadgeConfigFormData): string[] {
  const hexString = buildDataHexString(data);
  const chunks = splitHexStringIntoChunks(hexString);

  return chunks
    .map((chunk) => ByteArrayUtils.hexStringToByteArray(chunk))
    .map((bytes) => Base64.fromByteArray(bytes));
}

function buildDataHexString(data: BadgeConfigFormData): string {
  const {text, effects, speed, animation} = data;

  const payload = getLetterBitmaps(text).join('');
  const size = getSize(text);
  const timestamp = getTimestamp();
  const marquee = getMarqueeValue(effects.marquee);
  const flash = getFlashValue(effects.flash);
  const modes = `${speed}${animation}` + '00' + '00' + '00' + '00' + '00' + '00' + '00';

  return (
    HEADER + flash + marquee + modes + size + PADDING1 + timestamp + PADDING2 + SEPARATOR + payload
  );
}

const getMarqueeValue = (isMarrquee: boolean): string => {
  return isMarrquee ? '01' : '00';
};

const getFlashValue = (isFlash: boolean): string => {
  return isFlash ? '01' : '00';
};

function getLetterBitmaps(letters: string): string[] {
  const hexBitmaps: string[] = [];
  for (let i = 0; i < letters.length; i++) {
    const letter = letters[i];

    if (letter && isSupportedLetter(letter)) {
      const bitmap = LETTERS_HEX_BITMAPS[letter];
      hexBitmaps.push(bitmap);
    }
  }

  return hexBitmaps;
}

function getSize(letters: string): string {
  const size = letters.length;
  const firstBitmapSize = size.toString(16).padStart(4, '0');

  return firstBitmapSize + '0000'.repeat(MAX_BITMAPS_NUMBER - 1);
}

function getTimestamp(): string {
  const currentDate = new Date();
  const year = currentDate.getUTCFullYear();
  const month = currentDate.getUTCMonth() + 1; // JavaScript months are 0-indexed
  const day = currentDate.getUTCDate();
  const hours = currentDate.getUTCHours();
  const minutes = currentDate.getUTCMinutes();
  const seconds = currentDate.getUTCSeconds();

  const data = new Uint8Array(6);
  data[0] = year & 0xff;
  data[1] = month & 0xff;
  data[2] = day & 0xff;
  data[3] = hours & 0xff;
  data[4] = minutes & 0xff;
  data[5] = seconds & 0xff;

  return ByteArrayUtils.byteArrayToHexString(data);
}

function splitHexStringIntoChunks(hexString: string): string[] {
  const chunks = hexString.match(/.{1,32}/g) ?? [];

  return chunks.map((chunk) => chunk.padStart(HEX_CHARACTERS_PER_CHUNK, '0'));
}

function isSupportedLetter(letter: string): letter is SupportedLetter {
  return ALLOWED_CHARACTERS.includes(letter);
}
