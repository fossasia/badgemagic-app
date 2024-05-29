import {type SelectionType} from '@/models/SelectionType.model';

import animationImageSrc from '../assets/ic_anim_animation.gif';
import downImageSrc from '../assets/ic_anim_down.gif';
import fixedImageSrc from '../assets/ic_anim_fixed.gif';
import laserImageSrc from '../assets/ic_anim_laser.gif';
import leftImageSrc from '../assets/ic_anim_left.gif';
import pictureImageSrc from '../assets/ic_anim_picture.gif';
import rightImageSrc from '../assets/ic_anim_right.gif';
import upImageSrc from '../assets/ic_anim_up.gif';

export enum Animations {
  LEFT = 1,
  UP = 2,
  DOWN = 3,
  FIXED = 4,
  PICTURE = 5,
  LASER = 6,
  ANIMATION = 7,
  RIGHT = 0,
}

export const animations = [
  {
    imagePath: rightImageSrc,
    title: 'Left',
    code: Animations.LEFT,
  },
  {
    imagePath: upImageSrc,
    title: 'Up',
    code: Animations.UP,
  },
  {
    imagePath: downImageSrc,
    title: 'Down',
    code: Animations.DOWN,
  },
  {
    imagePath: fixedImageSrc,
    title: 'Fixed',
    code: Animations.FIXED,
  },
  {
    imagePath: pictureImageSrc,
    title: 'Picture',
    code: Animations.PICTURE,
  },
  {
    imagePath: animationImageSrc,
    title: 'Animation',
    code: Animations.ANIMATION,
  },
  {
    imagePath: laserImageSrc,
    title: 'Laser',
    code: Animations.LASER,
  },
  {
    imagePath: leftImageSrc,
    title: 'Right',
    code: Animations.RIGHT,
  },
] as const satisfies SelectionType[];
