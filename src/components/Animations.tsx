import {StyleSheet, View} from 'react-native';

import {useFormContext} from 'react-hook-form';

import {animations} from '@/utils/animations';

import {ControlledCard} from './CardControlled';

export const Animations = (): JSX.Element => {
  const {control} = useFormContext<FormData>();

  return (
    <View style={styles.cardsContainer}>
      {animations.map((animation) => (
        <ControlledCard
          key={animation.code}
          code={animation.code}
          imagePath={animation.imagePath}
          control={control}
          title={animation.title}
          name={'animation'}
        />
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  cardsContainer: {
    paddingTop: 16,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-evenly',
  },
});
