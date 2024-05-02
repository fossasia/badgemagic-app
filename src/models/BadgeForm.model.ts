export interface BadgeConfigFormData {
  text: string;
  effects: {
    flash: boolean;
    marquee: boolean;
    invertLed: boolean;
  };
  speed: number;
}
