import {Button, type ButtonProps} from 'react-native-paper';

interface AppButtonProps extends ButtonProps {
  onPress: () => Promise<void> | void;
}

export const AppButton = (props: AppButtonProps): JSX.Element => {
  return <Button mode="contained" {...props} />;
};
