import {type ImageSourcePropType} from 'react-native';

import flashImageSrc from '../assets/ic_effect_flash.gif';
import invertImageSrc from '../assets/ic_effect_invert.gif';
import marqueeImageSrc from '../assets/ic_effect_marquee.gif';

enum Effects {
  MARQUEE = 'marquee',
  FLASH = 'flash',
  INVERTEDLED = 'invertedLed',
}

interface EffectType {
  imagePath: ImageSourcePropType;
  placeholder: string;
  name: string;
}

export const effects = [
  {
    imagePath: flashImageSrc,
    placeholder: 'Flash',
    name: `effects.${Effects.FLASH}`,
  },
  {
    imagePath: marqueeImageSrc,
    placeholder: 'Marquee',
    name: `effects.${Effects.MARQUEE}`,
  },
  {
    imagePath: invertImageSrc,
    placeholder: 'Invert LED',
    name: `effects.${Effects.INVERTEDLED}`,
  },
] as const satisfies EffectType[];
