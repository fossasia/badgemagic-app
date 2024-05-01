import {useCallback, useEffect, useState} from 'react';
import {ActivityIndicator, Text, View} from 'react-native';

import * as Ble from 'dpld-ble';

import {type BadgeMagic} from '@/models/BadgeMagic.model';

import {AppButton} from './AppButton';

const BADGE_MAGIC_ADVERTISING_NAME = 'LSLED';

interface BadgeScanningProps {
  setScanning: (scanning: boolean) => void;
  scanning: boolean;
  connectedBadge: BadgeMagic | undefined;
  setConnectedBadge: (connectedBadge: BadgeMagic) => void;
}

export const BadgeScanning = ({
  setScanning,
  scanning,
  connectedBadge,
  setConnectedBadge,
}: BadgeScanningProps): JSX.Element => {
  const [discoveredBadges, setDiscoveredBadges] = useState<Record<string, BadgeMagic>>({});

  const scanForBadges = useCallback(() => {
    setDiscoveredBadges({});
    Ble.startScan();
    setScanning(true);
    setTimeout(() => {
      Ble.stopScan();
      setScanning(false);
    }, 3000);
  }, [setScanning]);

  useEffect(() => {
    if (connectedBadge) return;

    const discoveredBadgesList = Object.values(discoveredBadges);
    const badge = discoveredBadgesList[0];

    if (badge) {
      Ble.connect(badge.id);
    }
  }, [discoveredBadges, connectedBadge]);

  useEffect(() => {
    const discoverySub = Ble.addPeripheralDiscoveredListener((peripheral) => {
      if (peripheral.name !== BADGE_MAGIC_ADVERTISING_NAME) {
        return;
      }

      setDiscoveredBadges((prev: Record<string, BadgeMagic>) => {
        if (prev[peripheral.id]) {
          return prev;
        }

        console.log('Discovered badge', peripheral);

        return {
          ...prev,
          [peripheral.id]: {
            name: peripheral.name,
            id: peripheral.id,
          },
        };
      });
    });

    const connectionSub = Ble.addPeripheralConnectedListener((peripheral) => {
      console.log('Connected to badge', peripheral);
      setConnectedBadge(peripheral);
    });

    scanForBadges();

    return () => {
      discoverySub.remove();
      connectionSub.remove();
    };
  }, [scanForBadges]);

  return (
    <View>
      {scanning ? (
        <View>
          <ActivityIndicator size="large" />
          <Text>Scanning...</Text>
        </View>
      ) : (
        <AppButton disabled={scanning} onPress={scanForBadges}>
          Scan for badge
        </AppButton>
      )}
    </View>
  );
};
