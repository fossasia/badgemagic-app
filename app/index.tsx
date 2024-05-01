import {useState} from 'react';
import {StyleSheet, View} from 'react-native';

import {StatusBar} from 'expo-status-bar';
import {useForm, FormProvider} from 'react-hook-form';
import {SafeAreaProvider, SafeAreaView} from 'react-native-safe-area-context';

import {AppButton} from '@/components/AppButton';
import {BadgeForm} from '@/components/BadgeForm';
import {BadgeScanning} from '@/components/BadgeScanning';
import {type BadgeConfigFormData} from '@/models/BadgeForm.model';
import {type BadgeMagic} from '@/models/BadgeMagic.model';
import {sendPackets} from '@/utils/bluetooth';
import {getPackets} from '@/utils/payload';

const DefaultFormData: BadgeConfigFormData = {
  text: '',
  effects: {
    flash: false,
    marquee: false,
    invertLed: false,
  },
};

const Home = (): JSX.Element => {
  const [scanning, setScanning] = useState(false);
  const [connectedBadge, setConnectedBadge] = useState<BadgeMagic>();

  const methods = useForm<BadgeConfigFormData>({defaultValues: DefaultFormData});

  const handleSendToBadge = async (data: BadgeConfigFormData): Promise<void> => {
    if (!connectedBadge) {
      return;
    }
    console.log(data);
    const packets = getPackets(data);

    try {
      await sendPackets(connectedBadge.id, packets);
    } catch (e) {
      console.error(e);
    } finally {
      setConnectedBadge(undefined);
    }
  };

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        <StatusBar style="auto" />
        <FormProvider {...methods}>
          <BadgeForm />
          <View style={styles.buttonsContainer}>
            <AppButton
              disabled={scanning || !connectedBadge}
              onPress={methods.handleSubmit(handleSendToBadge)}>
              Send to badge
            </AppButton>
            <BadgeScanning
              setScanning={setScanning}
              connectedBadge={connectedBadge}
              scanning={scanning}
              setConnectedBadge={setConnectedBadge}
            />
          </View>
        </FormProvider>
      </SafeAreaView>
    </SafeAreaProvider>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 16,
  },
  buttonsContainer: {
    position: 'absolute',
    bottom: 40,
    gap: 8,
    left: 20,
    alignItems: 'center',
    justifyContent: 'space-between',
    flexDirection: 'row',
  },
});

export default Home;
