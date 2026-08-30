package org.fossasia.badgemagic;

import android.annotation.SuppressLint;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbConstants;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.os.Build;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "org.fossasia.badgemagic/wch_isp";
    private static final String ACTION_USB_PERMISSION = "org.fossasia.badgemagic.USB_PERMISSION";

    private MethodChannel.Result pendingPermissionResult = null;

    private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (ACTION_USB_PERMISSION.equals(action)) {
                synchronized (this) {
                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    boolean granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);

                    if (pendingPermissionResult != null) {
                        if (granted && device != null) {
                            pendingPermissionResult.success(true);
                        } else {
                            pendingPermissionResult.success(false);
                        }
                        pendingPermissionResult = null;
                    }
                }
            }
        }
    };

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(usbReceiver, filter);
        }

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);

                    if (call.method.equals("getIspDevice")) {
                        UsbDevice device = findWchDevice(usbManager);
                        if (device != null) {
                            Map<String, Object> map = new HashMap<>();
                            map.put("vid", device.getVendorId());
                            map.put("pid", device.getProductId());
                            map.put("hasPermission", usbManager.hasPermission(device));
                            result.success(map);
                        } else {
                            result.success(null);
                        }
                    } else if (call.method.equals("requestUsbPermission")) {
                        UsbDevice device = findWchDevice(usbManager);
                        if (device == null) {
                            result.error("DEVICE_NOT_FOUND", "Badge not found", null);
                            return;
                        }

                        if (usbManager.hasPermission(device)) {
                            result.success(true);
                            return;
                        }

                        pendingPermissionResult = result;

                        Intent intent = new Intent(ACTION_USB_PERMISSION);
                        intent.setPackage(getPackageName());

                        int flags = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) ? PendingIntent.FLAG_MUTABLE : 0;
                        PendingIntent permissionIntent = PendingIntent.getBroadcast(this, 0, intent, flags);
                        usbManager.requestPermission(device, permissionIntent);
                    } else if (call.method.equals("flashFirmware")) {
                        byte[] firmwareBytes = call.argument("firmware");
                        if (firmwareBytes == null) {
                            result.error("INVALID_ARGS", "Missing firmware data", null);
                            return;
                        }

                        UsbDevice device = findWchDevice(usbManager);
                        if (device == null) {
                            result.error("DEVICE_NOT_FOUND", "Badge not found", null);
                            return;
                        }

                        if (!usbManager.hasPermission(device)) {
                            result.error("PERMISSION_DENIED", "USB permission denied", null);
                            return;
                        }

                        new Thread(() -> {
                            try {
                                executeWchFlash(usbManager, device, firmwareBytes);
                                runOnUiThread(() -> result.success(true));
                            } catch (Exception e) {
                                runOnUiThread(() -> result.error("FLASH_ERROR", e.getMessage(), null));
                            }
                        }).start();
                    } else {
                        result.notImplemented();
                    }
                });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            unregisterReceiver(usbReceiver);
        } catch (Exception ignored) {}
    }

    private UsbDevice findWchDevice(UsbManager usbManager) {
        if (usbManager == null) return null;
        for (UsbDevice device : usbManager.getDeviceList().values()) {
            int vid = device.getVendorId();
            int pid = device.getProductId();
            if ((vid == 0x4348 && pid == 0x55E0) || (vid == 0x1A86 && pid == 0x55E0) || (vid == 0x1A86 && pid == 0xFE10)) {
                return device;
            }
        }
        return null;
    }

    private void executeWchFlash(UsbManager usbManager, UsbDevice device, byte[] rawFirmware) throws Exception {
        UsbDeviceConnection connection = usbManager.openDevice(device);
        if (connection == null) {
            throw new Exception("Unable to open USB connection");
        }

        UsbInterface intf = device.getInterface(0);
        connection.claimInterface(intf, true);

        UsbEndpoint epOut = null;
        UsbEndpoint epIn = null;

        for (int i = 0; i < intf.getEndpointCount(); i++) {
            UsbEndpoint ep = intf.getEndpoint(i);
            if (ep.getDirection() == UsbConstants.USB_DIR_OUT) {
                epOut = ep;
            } else if (ep.getDirection() == UsbConstants.USB_DIR_IN) {
                epIn = ep;
            }
        }

        if (epOut == null || epIn == null) {
            connection.releaseInterface(intf);
            connection.close();
            throw new Exception("Endpoint USB OUT or IN not found");
        }

        byte[] inBuffer = new byte[64];

        try {

            byte[] identify = new byte[21];
            identify[0] = (byte) 0xA1;
            identify[1] = 0x12;
            identify[2] = 0x00;
            identify[3] = 0x00;
            identify[4] = 0x00;
            byte[] magic = "MCU ISP & WCH.CN".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
            System.arraycopy(magic, 0, identify, 5, magic.length);

            int sent = connection.bulkTransfer(epOut, identify, identify.length, 1000);
            if (sent < 0) throw new Exception("Error sending IDENTIFY");
            int len = connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 1000);
            if (len < 6 || inBuffer[1] != 0x00) throw new Exception("IDENTIFY failed (status: " + inBuffer[1] + ")");

            byte chipId = inBuffer[4];
            Thread.sleep(30);

            byte[] readConfig = new byte[]{(byte) 0xA7, 0x02, 0x00, 0x1F, 0x00};
            sent = connection.bulkTransfer(epOut, readConfig, readConfig.length, 1000);
            if (sent < 0) throw new Exception("Error sending READ_CONFIG");
            len = connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 1000);
            if (len < 26 || inBuffer[1] != 0x00) throw new Exception("READ_CONFIG not valid");

            byte[] chipUid = new byte[8];
            System.arraycopy(inBuffer, 22, chipUid, 0, 8);

            int uidSum = 0;
            for (byte b : chipUid) {
                uidSum = (uidSum + (b & 0xFF)) & 0xFF;
            }

            byte[] xorKey = new byte[8];
            for (int i = 0; i < 7; i++) {
                xorKey[i] = (byte) uidSum;
            }
            xorKey[7] = (byte) ((uidSum + (chipId & 0xFF)) & 0xFF);

            int expectedKeyChecksum = 0;
            for (byte b : xorKey) {
                expectedKeyChecksum = (expectedKeyChecksum + (b & 0xFF)) & 0xFF;
            }
            Thread.sleep(30);

            byte[] firmware;
            if (rawFirmware.length % 1024 != 0) {
                int padding = 1024 - (rawFirmware.length % 1024);
                firmware = new byte[rawFirmware.length + padding];
                System.arraycopy(rawFirmware, 0, firmware, 0, rawFirmware.length);
            } else {
                firmware = rawFirmware;
            }

            int sectors = (firmware.length / 1024) + 1;
            if (sectors < 8) sectors = 8;

            byte[] erase = new byte[]{
                    (byte) 0xA4, 0x04, 0x00,
                    (byte) (sectors & 0xFF),
                    (byte) ((sectors >> 8) & 0xFF),
                    (byte) ((sectors >> 16) & 0xFF),
                    (byte) ((sectors >> 24) & 0xFF)
            };
            sent = connection.bulkTransfer(epOut, erase, erase.length, 1000);
            if (sent < 0) throw new Exception("Error sending ERASE");
            len = connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 6000);
            if (len < 2 || inBuffer[1] != 0x00) throw new Exception("Error clearing Flash");
            Thread.sleep(500);

            byte[] ispKeyCmd = new byte[3 + 0x1E];
            ispKeyCmd[0] = (byte) 0xA3;
            ispKeyCmd[1] = 0x1E;
            ispKeyCmd[2] = 0x00;

            sent = connection.bulkTransfer(epOut, ispKeyCmd, ispKeyCmd.length, 1000);
            if (sent < 0) throw new Exception("Error sending ISP_KEY");
            len = connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 1000);
            if (len < 5 || inBuffer[1] != 0x00) throw new Exception("ISP_KEY command failed");

            int receivedKeyChecksum = inBuffer[4] & 0xFF;
            if (receivedKeyChecksum != expectedKeyChecksum) {
                throw new Exception("Wrong checksum ISP_KEY: waited 0x" +
                        Integer.toHexString(expectedKeyChecksum) + " received 0x" +
                        Integer.toHexString(receivedKeyChecksum));
            }
            Thread.sleep(30);

            final int CHUNK = 56;
            int address = 0;

            while (address < firmware.length) {
                int end = Math.min(address + CHUNK, firmware.length);
                int chunkLen = end - address;
                int payloadSize = 1 + 4 + chunkLen;

                byte[] packet = new byte[3 + payloadSize];
                packet[0] = (byte) 0xA5;
                packet[1] = (byte) (payloadSize & 0xFF);
                packet[2] = (byte) ((payloadSize >> 8) & 0xFF);
                packet[3] = (byte) (address & 0xFF);
                packet[4] = (byte) ((address >> 8) & 0xFF);
                packet[5] = (byte) ((address >> 16) & 0xFF);
                packet[6] = (byte) ((address >> 24) & 0xFF);
                packet[7] = 0x00;

                for (int i = 0; i < chunkLen; i++) {
                    byte rawByte = firmware[address + i];
                    byte k = xorKey[i % 8];
                    packet[8 + i] = (byte) (rawByte ^ k);
                }

                sent = connection.bulkTransfer(epOut, packet, packet.length, 1000);
                if (sent < 0) throw new Exception("Error writing block to address 0x" + Integer.toHexString(address));

                len = connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 1000);
                if (len < 2 || inBuffer[1] != 0x00) {
                    throw new Exception("Failed ACK write to 0x" + Integer.toHexString(address));
                }

                address += chunkLen;
            }

            byte[] emptyPacket = new byte[]{
                    (byte) 0xA5, 0x05, 0x00,
                    (byte) (address & 0xFF),
                    (byte) ((address >> 8) & 0xFF),
                    (byte) ((address >> 16) & 0xFF),
                    (byte) ((address >> 24) & 0xFF),
                    0x00
            };
            connection.bulkTransfer(epOut, emptyPacket, emptyPacket.length, 1000);
            connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 1000);
            Thread.sleep(50);

            byte[] ispEnd = new byte[]{(byte) 0xA2, 0x01, 0x00, 0x01};
            connection.bulkTransfer(epOut, ispEnd, ispEnd.length, 1000);
            try {
                connection.bulkTransfer(epIn, inBuffer, inBuffer.length, 500);
            } catch (Exception ignored) {}

        } finally {
            connection.releaseInterface(intf);
            connection.close();
        }
    }
}