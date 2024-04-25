import {DefaultTheme, type MD3Theme} from 'react-native-paper';

export const theme: MD3Theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: 'red',
    onPrimary: 'fff',
  },
};
