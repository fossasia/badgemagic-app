import {type ImageSourcePropType, Text, StyleSheet} from 'react-native';

import {type FieldValues, type UseControllerProps, useController} from 'react-hook-form';
import {useTheme, Card} from 'react-native-paper';

type ControlledCardProps<T extends FieldValues> = {
  imagePath: ImageSourcePropType;
  title: string;
} & UseControllerProps<T>;

export const ControlledCard = <T extends FieldValues>({
  control,
  name,
  title,
  imagePath,
}: ControlledCardProps<T>): JSX.Element => {
  const {colors} = useTheme();

  const {
    field: {value, onChange},
  } = useController({name, control});

  const handleOnPress = (): void => {
    onChange(!value);
  };

  return (
    <Card
      onPress={handleOnPress}
      style={[{backgroundColor: value ? colors.primary : colors.onPrimary}, styles.card]}>
      <Card.Cover source={imagePath} style={styles.image} />
      <Card.Content>
        <Text>{title}</Text>
      </Card.Content>
    </Card>
  );
};

const styles = StyleSheet.create({
  card: {
    flex: 1,
    margin: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 10,
  },
  image: {
    backgroundColor: 'transparent',
    alignSelf: 'center',
    borderRadius: 2,
    margin: 5,
    width: 70,
    height: 70,
  },
});
