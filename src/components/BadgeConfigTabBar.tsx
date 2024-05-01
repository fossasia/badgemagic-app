import {Text} from 'react-native';

import {useTheme} from 'react-native-paper';
import {TabBar, type SceneRendererProps, type NavigationState} from 'react-native-tab-view';

type BadgeConfigTabBarProps = SceneRendererProps & {
  navigationState: NavigationState<{key: string; title: string}>;
};

export const BadgeConfigTabBar = (props: BadgeConfigTabBarProps): JSX.Element => {
  const {colors} = useTheme();

  return (
    <TabBar
      {...props}
      indicatorStyle={{backgroundColor: colors.primary}}
      style={{backgroundColor: 'transparent', shadowOpacity: 0}}
      renderLabel={({route, focused}) => (
        <Text style={{color: focused ? colors.secondary : colors.onSecondary, margin: 8}}>
          {route.title}
        </Text>
      )}
    />
  );
};
