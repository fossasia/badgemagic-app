import {useState} from 'react';
import {StyleSheet, View, useWindowDimensions} from 'react-native';

import {useFormContext} from 'react-hook-form';
import {SceneMap, TabView} from 'react-native-tab-view';

import {AppInput} from '@/components/AppInput';
import {tabRoutes} from '@/utils/tabRoutes';

import {type BadgeConfigFormData} from '../models/BadgeForm.model';
import {Animations} from './Animations';
import {BadgeConfigTabBar} from './BadgeConfigTabBar';
import {Effects} from './Effects';
import {SpeedSlider} from './Speed';

const renderScene = SceneMap({
  effects: Effects,
  animations: Animations,
  speed: SpeedSlider,
});

export const BadgeForm = (): JSX.Element => {
  const [index, setIndex] = useState(0);
  const [routes] = useState(tabRoutes);

  const {control} = useFormContext<BadgeConfigFormData>();
  const layout = useWindowDimensions();

  return (
    <View style={styles.inputContainer}>
      <AppInput control={control} placeholder={'Enter text'} name={'text'} />
      <TabView
        renderTabBar={BadgeConfigTabBar}
        navigationState={{index, routes}}
        renderScene={renderScene}
        onIndexChange={setIndex}
        initialLayout={{width: layout.width}}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  inputContainer: {
    paddingTop: 20,
    flex: 1,
    gap: 20,
  },
  cardsContainer: {
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-around',
  },
  selectionNavigation: {
    width: '100%',
    justifyContent: 'space-around',
    flexDirection: 'row',
    marginTop: 16,
    padding: 16,
  },
});
