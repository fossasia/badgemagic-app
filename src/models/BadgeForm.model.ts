import {type Animations} from '@/utils/animations';

export interface BadgeConfigFormData {
  text: string;
  effects: {
    flash: boolean;
    marquee: boolean;
    invertLed: boolean;
  };
  animation: Animations;
  speed: number;
}
