import 'dart:io';
import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/bluetooth/scan_state.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

Map<int, Mode> modeValueMap = {
  0: Mode.left,
  1: Mode.right,
  2: Mode.up,
  3: Mode.down,
  4: Mode.fixed,
  5: Mode.snowflake,
  6: Mode.picture,
  7: Mode.animation,
  8: Mode.laser
};

Map<int, Speed> speedMap = {
  1: Speed.one,
  2: Speed.two,
  3: Speed.three,
  4: Speed.four,
  5: Speed.five,
  6: Speed.six,
  7: Speed.seven,
  8: Speed.eight,
};

class BadgeMessageProvider {
  static final Logger logger = Logger();
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  FileHelper fileHelper = FileHelper();
  Converters converters = Converters();

  Future<Data> getBadgeData(String text, bool flash, bool marq, Speed speed,
      Mode mode, bool isInverted) async {
    List<String> message = await converters.messageTohex(text, isInverted);
    Data data = Data(messages: [
      Message(
        text: message,
        flash: flash,
        marquee: marq,
        speed: speed,
        mode: mode,
      )
    ]);
    return data;
  }

  Future<Data> generateData(
      String? text,
      bool? flash,
      bool? marq,
      bool? inverted,
      Speed? speed,
      Mode? mode,
      Map<String, dynamic>? jsonData) async {
    if (jsonData != null) {
      return fileHelper.jsonToData(jsonData);
    } else {
      return getBadgeData(text ?? '', flash ?? false, marq ?? false,
          speed ?? Speed.one, mode ?? Mode.left, inverted ?? false);
    }
  }

  Future<void> transferData(DataTransferManager manager) async {
    DateTime now = DateTime.now();
    BleState? state = ScanState(manager: manager);
    while (state != null) {
      state = await state.process();
    }

    logger.d("Time to transfer data is = ${DateTime.now().difference(now)}");
    logger.d(".......Data transfer completed.......");
  }

  Future<void> checkAndTransfer(
      String? text,
      bool? flash,
      bool? marq,
      bool? isInverted,
      int? speed,
      Mode? mode,
      Map<String, dynamic>? jsonData,
      bool isSavedBadge) async {
    if (await FlutterBluePlus.isSupported == false) {
      ToastUtils().showErrorToast('Bluetooth is not supported by the device');
      return;
    }

    if (controllerData.getController().text.isEmpty && isSavedBadge == false) {
      ToastUtils().showErrorToast("Please enter a message");
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.on) {
      Data data;
      if (jsonData != null) {
        data = fileHelper.jsonToData(jsonData);
      } else {
        data = await generateData(
            text, flash, marq, isInverted, speedMap[speed], mode, jsonData);
      }
      DataTransferManager manager = DataTransferManager(data);
      await transferData(manager);
    } else {
      if (Platform.isAndroid) {
        ToastUtils().showToast('Turning on Bluetooth...');
        await FlutterBluePlus.turnOn();
      } else if (Platform.isIOS) {
        ToastUtils().showToast('Please turn on Bluetooth');
      }
    }
  }
}
