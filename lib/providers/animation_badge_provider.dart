import 'dart:async';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/badge_animation/ani_animation.dart';
import 'package:badgemagic/badge_animation/ani_down.dart';
import 'package:badgemagic/badge_animation/ani_fixed.dart';
import 'package:badgemagic/badge_animation/ani_laser.dart';
import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/ani_picture.dart';
import 'package:badgemagic/badge_animation/ani_right.dart';
import 'package:badgemagic/badge_animation/ani_snowflake.dart';
import 'package:badgemagic/badge_animation/ani_up.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';

Map<int, BadgeAnimation?> animationMap = {
  0: LeftAnimation(),
  1: RightAnimation(),
  2: UpAnimation(),
  3: DownAnimation(),
  4: FixedAnimation(),
  5: SnowFlakeAnimation(),
  6: PictureAnimation(),
  7: AniAnimation(),
  8: LaserAnimation(),
};

Map<int, BadgeEffect> effectMap = {
  0: InvertLEDEffect(),
  1: FlashEffect(),
  2: MarqueeEffect(),
};

enum EffectType { flash, invert, marquee }

class AnimationBadgeProvider extends ChangeNotifier {
  int _animationIndex = 0;
  int _animationSpeed = aniSpeedStrategy(0);
  Timer? _timer;

  //List that contains the state of each cell of the badge for home view
  List<List<bool>> _paintGrid =
      List.generate(11, (i) => List.generate(44, (j) => false));

  BadgeAnimation _currentAnimation = LeftAnimation();

  final Set<BadgeEffect?> _currentEffect = {};

  //function to get the state of the cell
  List<List<bool>> getPaintGrid() => _paintGrid;

  //function to calculate duration for the animation
  void calculateDuration(int speed) {
    int newSpeed = aniSpeedStrategy(speed - 1);
    if (newSpeed != _animationSpeed) {
      _animationSpeed = newSpeed;
      _timer?.cancel();
      startTimer();
    }
  }

  List<List<bool>> _newGrid =
      List.generate(11, (i) => List.generate(44, (j) => false));

  //getter for newGrid
  List<List<bool>> getNewGrid() => _newGrid;

  //setter for newGrid
  void setNewGrid(List<List<bool>> grid) {
    _newGrid = grid;
    _animationIndex = 0;
    notifyListeners();
  }

  Set<BadgeEffect?> get getCurrentEffect => _currentEffect;

  void addEffect(BadgeEffect? effect) {
    _currentEffect.add(effect);
    logger.i("Effect Added: $effect : $_currentEffect");
    notifyListeners();
  }

  void removeEffect(BadgeEffect? effect) {
    _currentEffect.remove(effect);
    notifyListeners();
  }

  bool isEffectActive(BadgeEffect? effect) {
    return _currentEffect.contains(effect);
  }

  void initializeAnimation() {
    if (_timer == null) {
      startTimer();
    }
  }

  //function to stop timer and reset the animationIndex
  void stopAnimation() {
    logger.d("Timer stopped  ${_timer?.tick.toString()}");
    _timer?.cancel();

    _animationIndex = 0;
  }

  void stopAllAnimations() {
    // Stop any ongoing timer and reset the animation index
    stopAnimation();
    _currentAnimation = LeftAnimation();
    // Reset the grids to all false values
    _paintGrid = List.generate(11, (i) => List.generate(44, (j) => false));
    _newGrid = List.generate(11, (i) => List.generate(44, (j) => false));
    logger.d("All animations stopped");
  }

  void startTimer() {
    _timer =
        Timer.periodic(Duration(microseconds: _animationSpeed), (Timer timer) {
      // logger.i(
      //     "New Grid set to: ${getNewGrid().map((e) => e.map((e) => e ? 1 : 0).toList()).toList()}");
      renderGrid(getNewGrid());
      _animationIndex++;
    });
  }

  void setAnimationMode(BadgeAnimation? animation) {
    _animationIndex = 0;
    _currentAnimation = animation ?? LeftAnimation();
    notifyListeners();
    logger.i("Animation Mode set to: $_currentAnimation");
  }

  int? getAnimationIndex() {
    for (var animation in animationMap.entries) {
      if (animation.value != null && animation.value == _currentAnimation) {
        logger.i("Animation Index: ${animation.key}");
        return animation.key;
      }
    }
    return 0;
  }

  bool isAnimationActive(BadgeAnimation? badgeAnimation) {
    bool isActive = _currentAnimation == badgeAnimation;
    return isActive;
  }

  void badgeAnimation(
      String message, Converters converters, bool isInverted) async {
    if (message == "") {
      //geerate a 2d list with all values as 0
      List<List<bool>> image =
          List.generate(11, (i) => List.generate(44, (j) => false));
      setNewGrid(image);
    } else {
      List<String> hexString =
          await converters.messageTohex(message, isInverted);
      List<List<bool>> binaryArray = hexStringToBool(hexString.join());
      setNewGrid(binaryArray);
    }
  }

  void renderGrid(List<List<bool>> newGrid) {
    int badgeWidth = _paintGrid[0].length;
    int badgeHeight = _paintGrid.length;

    var canvas = List.generate(
        badgeHeight, (i) => List.generate(badgeWidth, (j) => false));

    _currentAnimation.processAnimation(
        badgeHeight, badgeWidth, _animationIndex, newGrid, canvas);

    for (var effect in _currentEffect) {
      effect?.processEffect(_animationIndex, canvas, badgeHeight, badgeWidth);
    }

    _paintGrid = canvas;
    notifyListeners();
  }
}
