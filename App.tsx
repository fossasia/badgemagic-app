import { StatusBar } from "expo-status-bar";
import {
  ActivityIndicator,
  Button,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import * as Ble from "dpld-ble";
import { useCallback, useEffect, useRef, useState } from "react";
import { getPackets } from "@/utils/payload";
import { sendPackets } from "@/utils/bluetooth";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

type BadgeMagic = {
  name?: string;
  id: string;
};

const BADGE_MAGIC_ADVERTISING_NAME = "LSLED";

export default function App() {
  const [text, setText] = useState("");
  const [scanning, setScanning] = useState(false);
  const [error, setError] = useState<string>();
  const [discoveredBadges, setDiscoveredBadges] = useState<
    Record<string, BadgeMagic>
  >({});
  const [connectedBadge, setConnectedBadge] = useState<BadgeMagic>();

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
    const discoverySub = Ble.addPeripheralDiscoveredListener((peripheral) => {
      console.log("Discovered badge", peripheral);

      if (peripheral.name !== BADGE_MAGIC_ADVERTISING_NAME) {
        return;
      }

      setDiscoveredBadges((prev) => {
        if (prev[peripheral.id]) {
          return prev;
        }

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
      console.log("Connected to badge", peripheral);
      setConnectedBadge(peripheral);
    });

    scanForBadges();

    return () => {
      discoverySub.remove();
      connectionSub.remove();
    };
  }, [scanForBadges]);

  useEffect(() => {
    const discoveredBadgesList = Object.values(discoveredBadges);
    if (!connectedBadge && discoveredBadgesList.length > 0) {
      const badge = discoveredBadgesList[0];
      Ble.connect(badge.id);
    }
  }, [discoveredBadges, connectedBadge]);

  const handleSendToBadge = async () => {
    if (!connectedBadge) {
      return;
    }

    const packets = getPackets(text);

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
        <View style={styles.inputContainer}>
          <Text>Enter text:</Text>
          <TextInput value={text} style={styles.input} onChangeText={setText} />
          {connectedBadge ? (
            <Button
              title="Send to badge"
              disabled={scanning}
              onPress={handleSendToBadge}
            />
          ) : (
            <Text>No badge connected...</Text>
          )}
        </View>
        <View style={styles.divider} />
        <View style={styles.scanContainer}>
          {scanning ? (
            <View>
              <ActivityIndicator size="large" />
              <Text>Scanning...</Text>
            </View>
          ) : (
            <Button
              title="Scan for badges"
              disabled={scanning}
              onPress={scanForBadges}
            />
          )}
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  inputContainer: {
    flex: 4,
    rowGap: 8,
    justifyContent: "center",
    alignItems: "center",
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: "#d3d3d3",
  },
  input: {
    width: 300,
    fontSize: 20,
    borderRadius: 30,
    borderWidth: StyleSheet.hairlineWidth,
    padding: 10,
  },
  scanContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
