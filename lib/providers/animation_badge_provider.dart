import 'dart:async';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
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
import 'package:badgemagic/badge_animation/ani_pacman.dart';
import 'package:badgemagic/badge_animation/ani_chevron_left.dart';
import 'package:badgemagic/badge_animation/ani_diamond.dart';
import 'package:badgemagic/badge_animation/ani_broken_hearts.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';

import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:badgemagic/badge_animation/ani_diagonal.dart';

import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/badge_animation/ani_fireworks.dart';
import 'package:badgemagic/badge_animation/ani_equalizer.dart'; // new import of EqualizerAnimation

Map<int, BadgeAnimation?> animationMap = {
  0: LeftAnimation(),
  1: RightAnimation(),
  2: UpAnimation(),
  3: DownAnimation(),
  4: FixedAnimation(),
  5: AniAnimation(),
  6: SnowFlakeAnimation(),
  7: PictureAnimation(),
  8: LaserAnimation(),
  9: PacmanClassicAnimation(), // Pacman
  10: LeftChevronAnimation(), // Chevron left
  11: DiamondAnimation(), // Diamond
  12: BrokenHeartsAnimation(), // Broken Hearts
  13: CupidAnimation(), // Cupid
  14: FeetAnimation(), // Feet
  15: FishAnimation(), // Fish
  16: DiagonalAnimation(), // Diagonal
  17: EmergencyAnimation(), // Emergency
  18: BeatingHeartsAnimation(), // Beating Hearts
  19: FireworksAnimation(), // Fireworks
  20: EqualizerAnimation(), // Digital Rain
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

  // Helper: returns true if a special animation (custom) is selected
  bool isSpecialAnimationSelected() {
    int idx = getAnimationIndex() ?? 0;
    // Add all special animation indices here (including Equalizer at 20):
    return [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].contains(idx);
  }

  // Call this to reset to text animation (LeftAnimation)
  void resetToTextAnimation() {
    setAnimationMode(LeftAnimation());
  }

  //function to calculate duration for the animation
  void calculateDuration(int speed) {
    int idx = getAnimationIndex() ?? 0;
    int newSpeed;
    if (idx == 9 || idx == 10 || idx == 11 || idx == 12 || idx == 20) {
      //added EqualizerAnimation
      // Use slower mapping for custom animations
      // (aniSpeedStrategy already uses the slower mapping if you want, or you can hardcode)
      newSpeed = aniSpeedStrategy(speed - 1); // keep as is, or adjust if needed
    } else {
      // Use original (faster) mapping for text/standard animations
      // For original: aniBaseSpeed = 200000us, minSpeed = 25000us (example)
      const int originalBase = 200000;
      const int minSpeed = 25000;
      newSpeed = originalBase - ((speed - 1) * (originalBase - minSpeed) ~/ 8);
    }
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

  /// Clears all currently active effects
  void clearAllEffects() {
    _currentEffect.clear();
    notifyListeners();
  }

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
      renderGrid(getNewGrid());
      if (_currentAnimation is CupidAnimation) {
        int frameLimit =
            CupidAnimation.frameCount(_paintGrid[0].length, _paintGrid.length);
        _animationIndex = (_animationIndex + 1) % frameLimit;
      } else {
        _animationIndex++;
      }
    });
  }

  void setAnimationMode(BadgeAnimation? animation) {
    // Always reset the animation index and set the new animation
    _animationIndex = 0;
    _currentAnimation = animation ?? LeftAnimation();
    // Stop the timer if running
    _timer?.cancel();
    // Start the timer for the new animation
    startTimer();
    notifyListeners();
    logger.i("Animation Mode set to: $_currentAnimation and timer restarted");
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
    bool isSpecial = isSpecialAnimationSelected();
    if (message.isEmpty && !isSpecial) {
      stopAllAnimations();
      List<List<bool>> emptyGrid =
          List.generate(11, (i) => List.generate(44, (j) => false));
      _newGrid = emptyGrid;
      _paintGrid = emptyGrid;
      notifyListeners();
      return;
    }
    if (_timer == null || !_timer!.isActive) {
      startTimer();
    }
    List<String> hexString = await converters.messageTohex(message, isInverted);
    List<List<bool>> binaryArray = hexStringToBool(hexString.join());
    setNewGrid(binaryArray);
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

  /// Handles animation transfer selection logic for the current animation index.
  Future<void> handleAnimationTransfer({
    required BadgeMessageProvider badgeData,
    required InlineImageProvider inlineImageProvider,
    required SpeedDialProvider speedDialProvider,
    required bool flash,
    required bool marquee,
    required bool invert,
  }) async {
    final int aniIndex = getAnimationIndex() ?? 0;
    final int selectedSpeed = speedDialProvider.getOuterValue();
    if (aniIndex == 9) {
      // Pacman
      await transferPacmanAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 10) {
      await transferChevronAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 11) {
      await transferDiamondAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 12) {
      await transferBrokenHeartsAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 13) {
      await transferCupidAnimation(badgeData, selectedSpeed);
      setAnimationMode(CupidAnimation());
      _animationIndex = 0;
      if (_timer == null || !_timer!.isActive) startTimer();
    } else if (aniIndex == 14) {
      await transferFeetAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 15) {
      await transferFishAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 16) {
      await transferDiagonalAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 17) {
      await transferEmergencyAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 18) {
      await transferBeatingHeartsAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 19) {
      await transferFireworksAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 20) {
      await transferEqualizerAnimation(badgeData, selectedSpeed);
    } else {
      await badgeData.checkAndTransfer(
        inlineImageProvider.getController().text,
        flash,
        marquee,
        invert,
        selectedSpeed,
        modeValueMap[aniIndex],
        null,
        false,
      );
    }
  }
}
