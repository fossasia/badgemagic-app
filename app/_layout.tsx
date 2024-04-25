import {Stack} from 'expo-router';
import {Provider as PaperProvider, useTheme} from 'react-native-paper';

import {theme} from '@/theme';

export default function Layout(): JSX.Element {
  return (
    <PaperProvider theme={theme}>
      <AppStack />
    </PaperProvider>
  );
}

const AppStack = (): JSX.Element => {
  const {colors} = useTheme();

  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.primary,
        },
        headerTintColor: colors.onPrimary,
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      }}>
      <Stack.Screen name="index" options={{}} />
    </Stack>
  );
};
