import {StyleSheet, View, Text} from 'react-native';

import Slider from '@react-native-community/slider';
import {useController, useFormContext} from 'react-hook-form';
import {useTheme} from 'react-native-paper';

import {type BadgeConfigFormData} from '@/models/BadgeForm.model';

export const SpeedSlider = (): JSX.Element => {
  const {control} = useFormContext<BadgeConfigFormData>();
  const {colors} = useTheme();

  const {
    field: {value, onChange},
  } = useController({name: 'speed', control});

  return (
    <View style={styles.container}>
      <Text style={styles.text}>{value}</Text>
      <Slider
        style={styles.slider}
        step={1}
        minimumValue={0}
        maximumValue={7}
        minimumTrackTintColor={colors.onPrimary}
        maximumTrackTintColor={colors.primary}
        value={value}
        onValueChange={onChange}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 32,
    textAlign: 'center',
  },
  slider: {
    width: '100%',
    height: 40,
  },
  text: {
    textAlign: 'center',
  },
});
