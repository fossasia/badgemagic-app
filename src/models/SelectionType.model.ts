import {type ImageSourcePropType} from 'react-native';

export interface SelectionType {
  imagePath: ImageSourcePropType;
  title: string;
  name?: string;
  code?: number;
}
