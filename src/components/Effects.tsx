import {StyleSheet, View} from 'react-native';

import {useFormContext} from 'react-hook-form';

import {effects} from '@/utils/effects';

import {ControlledCard} from './CardControlled';

export const Effects = (): JSX.Element => {
  const {control} = useFormContext<FormData>();

  return (
    <View style={styles.cardsContainer}>
      {effects.map((effect) => (
        <ControlledCard
          key={effect.name}
          imagePath={effect.imagePath}
          control={control}
          title={effect.placeholder}
          name={effect.name}
        />
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  cardsContainer: {
    paddingTop: 16,
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-around',
  },
});
