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

  // List that contains the state of each cell of the badge for home view
  List<List<bool>> _paintGrid =
      List.generate(11, (i) => List.generate(44, (j) => false));

  BadgeAnimation _currentAnimation = LeftAnimation();

  final Set<BadgeEffect?> _currentEffect = {};

  TextStyle? _textStyle;

  TextStyle? get textStyle => _textStyle;

  void setTextStyle(TextStyle textStyle) {
    _textStyle = textStyle;
    notifyListeners();
  }

  // New: store the current message for display purposes
  String _currentMessage = "";
  String get currentMessage => _currentMessage;

  // Function to get the state of the cell
  List<List<bool>> getPaintGrid() => _paintGrid;

  // Function to calculate duration for the animation
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

  // Getter for newGrid
  List<List<bool>> getNewGrid() => _newGrid;

  // Setter for newGrid
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

  // Function to stop timer and reset the animationIndex
  void stopAnimation() {
    logger.d("Timer stopped  ${_timer?.tick.toString()}");
    _timer?.cancel();
    _animationIndex = 0;
  }

  void stopAllAnimations() {
    stopAnimation();
    _currentAnimation = LeftAnimation();
    _paintGrid = List.generate(11, (i) => List.generate(44, (j) => false));
    _newGrid = List.generate(11, (i) => List.generate(44, (j) => false));
    logger.d("All animations stopped");
  }

  void startTimer() {
    _timer =
        Timer.periodic(Duration(microseconds: _animationSpeed), (Timer timer) {
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

  // It stores the current message and calls the new renderTextToMatrix converter.
  void badgeAnimation(String message, Converters converters, bool isInverted,
      {required TextStyle textStyle}) async {
    _currentMessage = message;
    setTextStyle(textStyle);
    if (message == "") {
      List<List<bool>> image =
          List.generate(11, (i) => List.generate(44, (j) => false));
      setNewGrid(image);
    } else {
      // Render the text using the selected font style
      List<List<bool>> matrix =
          await converters.renderTextToMatrix(message, textStyle);
      if (isInverted) {
        matrix =
            matrix.map((row) => row.map((cell) => !cell).toList()).toList();
      }
      setNewGrid(matrix);
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
