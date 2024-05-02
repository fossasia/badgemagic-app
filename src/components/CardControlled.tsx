import {type ImageSourcePropType, Text, StyleSheet} from 'react-native';

import {type FieldValues, type UseControllerProps, useController} from 'react-hook-form';
import {useTheme, Card} from 'react-native-paper';

import {type Animations} from '@/utils/animations';

type ControlledCardProps<T extends FieldValues> = {
  imagePath: ImageSourcePropType;
  title: string;
  code?: Animations;
} & UseControllerProps<T>;

export const ControlledCard = <T extends FieldValues>({
  control,
  name,
  code,
  title,
  imagePath,
}: ControlledCardProps<T>): JSX.Element => {
  const {colors} = useTheme();
  const isAnimationSelected = name === 'animation';

  const {
    field: {value, onChange},
  } = useController({name, control});

  const handleOnPress = (): void => {
    onChange(isAnimationSelected ? code : !value);
  };

  const cardColor = isAnimationSelected
    ? value === code
      ? colors.primary
      : colors.onPrimary
    : value
      ? colors.primary
      : colors.onPrimary;

  return (
    <Card onPress={handleOnPress} style={[{backgroundColor: cardColor}, styles.card]}>
      <Card.Cover source={imagePath} style={styles.image} />
      <Card.Content>
        <Text style={styles.text}>{title}</Text>
      </Card.Content>
    </Card>
  );
};

const styles = StyleSheet.create({
  card: {
    marginTop: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 10,
  },
  image: {
    backgroundColor: 'transparent',
    alignSelf: 'center',
    borderRadius: 2,
    margin: 5,
    width: 90,
    height: 90,
  },
  text: {
    textAlign: 'center',
  },
});
