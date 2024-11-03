import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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

class SavedBadgeProvider extends ChangeNotifier {
  Converters converters = Converters();
  FileHelper fileHelper = FileHelper();
  bool isSavedBadgeData = false;
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();

  void setIsSavedBadgeData(bool value) {
    isSavedBadgeData = value;
    notifyListeners();
  }

  void saveBadgeData(String filename, String message, bool isFlash,
      bool isMarquee, bool isInvert, int? speed, int animation) async {
    Data data = await getBadgeData(
      message,
      isFlash, //needs aniEffectProvider
      isMarquee,
      isInvert, //needs Anieffect provider
      speedMap[speed] ?? Speed.one, //needs speed dial provider
      modeValueMap[animation]!,
    );
    fileHelper.saveBadgeData(
        data, filename, isInvert); //needs AniEffectProvider
  }

  Future<Data> getBadgeData(String text, bool flash, bool marq, bool isInverted,
      Speed speed, Mode mode) async {
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

  void savedBadgeAnimation(
      Map<String, dynamic> data, AnimationBadgeProvider aniProvider) {
    //set the animations and the modes from the json file
    logger.i(Speed.getIntValue(Speed.fromHex(data['messages'][0]['speed'])));
    aniProvider.calculateDuration(
        Speed.getIntValue(Speed.fromHex(data['messages'][0]['speed'])) + 1);
    aniProvider.setAnimationMode(animationMap[
        Mode.getIntValue(Mode.fromHex(data['messages'][0]['mode']))]);

    if (data['messages'][0]['invert'] == true) {
      aniProvider.addEffect(effectMap[0]);
    }

    if (data['messages'][0]['flash'] == true) {
      aniProvider.addEffect(effectMap[1]);
    }

    if (data['messages'][0]['marquee'] == true) {
      aniProvider.addEffect(effectMap[2]);
    }

    logger.i("Effects set are = ${aniProvider.getCurrentEffect}");

    String hexString = data['messages'][0]['text'].join();
    List<List<bool>> binaryArray = hexStringToBool(hexString);
    aniProvider.setNewGrid(binaryArray);
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  Map<String, dynamic> savedBadgeData = {};

  void setSavedBadgeDataMap(Map<String, dynamic> data) {
    savedBadgeData = data;
    notifyListeners();
  }

  Map<String, dynamic> getSavedBadgeDataMap() => savedBadgeData;
}
