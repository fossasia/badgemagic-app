import {StyleSheet} from 'react-native';

import {type FieldValues, useController, type Path, type Control} from 'react-hook-form';
import {TextInput, useTheme, type TextInputProps} from 'react-native-paper';

export type AppInputProps<T extends FieldValues> = {
  placeholder: string;
  name: Path<T>;
  control: Control<T>;
} & Omit<TextInputProps, 'value' | 'onTextChange' | 'mode' | 'outlineColor'>;

export const AppInput = <T extends FieldValues>({
  control,
  name,
  ...props
}: AppInputProps<T>): JSX.Element => {
  const {colors} = useTheme();

  const {
    field: {onChange, value},
  } = useController({name, control});

  return (
    <TextInput
      {...props}
      mode="outlined"
      outlineColor="transparent"
      style={[{backgroundColor: colors.onPrimary}, styles.input, props.style]}
      value={value}
      onChangeText={onChange}
    />
  );
};

const styles = StyleSheet.create({
  input: {
    width: '100%',
    padding: 8,
  },
});
