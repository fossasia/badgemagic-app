import 'dart:async';
import 'dart:typed_data';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/badge_animation/ani_splitting.dart';
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
import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:badgemagic/badge_animation/ani_diagonal.dart';
import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/badge_animation/ani_fireworks.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';
import 'package:badgemagic/badge_animation/ani_equalizer.dart'; // new import of EqualizerAnimation
import 'package:badgemagic/badge_animation/ani_cycle.dart';
import 'package:universal_ble/universal_ble.dart';

import '../bademagic_module/bluetooth/completed_state.dart';
import '../bademagic_module/bluetooth/datagenerator.dart';
import '../globals/globals.dart';
import 'next_gen_provider.dart';

Map<int, BadgeAnimation?> animationMap = {
  0: LeftAnimation(),
  1: RightAnimation(),
  2: UpAnimation(),
  3: DownAnimation(),
  4: FixedAnimation(),
  5: SplittingAnimation(),
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
  21: CycleAnimation(), // Cycle
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
    // Add all special animation indices here (including Equalizer at 20 and Cycle at 20):
    return [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21].contains(idx);
  }

  // Call this to reset to text animation (LeftAnimation)
  void resetToTextAnimation() {
    setAnimationMode(LeftAnimation());
  }

  //function to calculate duration for the animation
  void calculateDuration(int speed) {
    int idx = getAnimationIndex() ?? 0;
    int newSpeed;
    if (idx == 9 ||
        idx == 10 ||
        idx == 11 ||
        idx == 12 ||
        idx == 20 ||
        idx == 21) {
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        return animation.key;
      }
    }
    return 0;
  }

  StreamSubscription<Uint8List>? _ngNotifySubscription;
  Completer<void>? _frameAckCompleter;

  bool _isNgConnected = false;
  bool get isNgConnected => _isNgConnected;

  String _ngDeviceName = "LED Badge Magic";
  String get ngDeviceName => _ngDeviceName;

  int _ngBrightness = 1;
  int get ngBrightness => _ngBrightness;

  DataTransferManager? _ngManager;
  DataTransferManager? get ngManager => _ngManager;

  BleDevice? _ngDevice;
  BleDevice? get ngDevice => _ngDevice;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  void setNgConnected(bool connected,
      {DataTransferManager? manager, BleDevice? device}) {
    _isNgConnected = connected;
    if (connected) {
      _ngManager = manager;
      _ngDevice = device;
      if (device != null && device.name != null && device.name!.isNotEmpty) {
        _ngDeviceName = device.name!;
      }
    }
    notifyListeners();
  }

  void setNgDeviceName(String newName) {
    _ngDeviceName = newName;
    notifyListeners();
  }

  void setNgBrightness(int level) {
    _ngBrightness = level;
    notifyListeners();
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
  Future<CompletedState?> handleAnimationTransfer({
    required BadgeMessageProvider badgeData,
    required InlineImageProvider inlineImageProvider,
    required SpeedDialProvider speedDialProvider,
    required bool flash,
    required bool marquee,
    required bool invert,
    required BuildContext context,
  }) async {
    final int aniIndex = getAnimationIndex() ?? 0;
    final int selectedSpeed = speedDialProvider.getOuterValue();

    dynamic transferResult;

    if (aniIndex == 9) {
      // Pacman
      await transferPacmanAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 10) {
      await transferChevronAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 11) {
      await transferDiamondAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 12) {
      await transferBrokenHeartsAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 13) {
      await transferCupidAnimation(badgeData, selectedSpeed, context);
      setAnimationMode(CupidAnimation());
      _animationIndex = 0;
      if (_timer == null || !_timer!.isActive) startTimer();
    } else if (aniIndex == 14) {
      await transferFeetAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 15) {
      await transferFishAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 16) {
      await transferDiagonalAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 17) {
      await transferEmergencyAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 18) {
      await transferBeatingHeartsAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 19) {
      await transferFireworksAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 20) {
      await transferEqualizerAnimation(badgeData, selectedSpeed, context);
    } else if (aniIndex == 21) {
      await transferCycleAnimation(badgeData, selectedSpeed, context);
    } else {
      transferResult = await badgeData.checkAndTransfer(
        inlineImageProvider.getController().text,
        flash,
        marquee,
        invert,
        selectedSpeed,
        modeValueMap[aniIndex],
        null,
        false,
        context,
      );
    }
    if (transferResult is CompletedState) {
      return transferResult;
    }
    return null;
  }

  Future<void> sendDirectLegacyUpdate({
    required String text,
    required dynamic badgeData,
    required bool flash,
    required bool marquee,
    required bool invert,
    required int speed,
  }) async {
    if (!_isNgConnected || _ngDevice == null) return;

    final String? deviceId = _ngDevice?.deviceId;

    try {
      final data = await badgeData.generateData(
        text,
        flash,
        marquee,
        invert,
        speedMap[speed],
        animationMap[getAnimationIndex() ?? 0],
        null,
      );

      final DataTransferManager temporaryManager = DataTransferManager(data);
      List<List<int>> dataChunks = await temporaryManager.generateDataChunk();

      logger.d(
          "Next-Gen Channel: Starting writing legacy packets on active link");

      for (List<int> chunk in dataChunks) {
        await UniversalBle.write(
          deviceId!,
          serviceUuid, // 0xFEE0
          characteristicUuid, // 0xFEE1
          Uint8List.fromList(chunk),
          withoutResponse: false,
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      logger.i("Next-Gen Channel: Badge updated successfully via direct flow!");
    } catch (e) {
      logger.e("Error during direct Next-Gen update: $e");
    }
  }

  Uint8List encodeGridToNgFrame(List<List<bool>> grid) {
    final Uint8List packet = Uint8List(89);
    packet[0] = 0x03;

    final int rows = grid.length; // 11
    final int cols = grid[0].length; // 44

    for (int c = 0; c < cols; c++) {
      int columnWord = 0;
      for (int r = 0; r < rows; r++) {
        if (grid[r][c]) {
          columnWord |= (1 << r);
        }
      }

      int byteOffset = 1 + (c * 2);
      packet[byteOffset] = columnWord & 0xFF; // LSB
      packet[byteOffset + 1] = (columnWord >> 8) & 0xFF; // MSB
    }

    return packet;
  }

  /// Starts the real-time streaming session on the badge
  Future<void> startLiveStreaming() async {
    if (!_isNgConnected || _ngDevice == null || _isStreaming) return;

    final String? deviceId = _ngDevice?.deviceId;
    _isStreaming = true;
    notifyListeners();

    try {
      await UniversalBle.subscribeNotifications(
          deviceId!, ngServiceUuid, ngNotifyCharUuid);

      _ngNotifySubscription =
          UniversalBle.characteristicValueStream(deviceId, ngNotifyCharUuid)
              .listen(
        (Uint8List value) {
          if (value.isNotEmpty && value[0] == 0x00) {
            if (_frameAckCompleter != null &&
                !_frameAckCompleter!.isCompleted) {
              _frameAckCompleter!.complete();
            }
          } else if (value.isNotEmpty) {
            logger.w(
                "Next-Gen Badge returned an error or warning code: 0x${value[0].toRadixString(16)}");
          }
        },
      );

      await UniversalBle.write(
        deviceId,
        ngServiceUuid,
        ngWriteCharUuid,
        Uint8List.fromList(NgCommand.enterStreaming()),
        withoutResponse: false,
      );

      logger.i("Live Streaming mode activated on the badge.");

      _runStreamingLoop();
    } catch (e) {
      logger.e("Unable to activate Live Streaming: $e");
      stopLiveStreaming();
    }
  }

  /// Internal asynchronous loop throttled at ~25-30 FPS with GATT backpressure control
  void _runStreamingLoop() async {
    final String? deviceId = _ngDevice?.deviceId;
    final Duration frameDuration = const Duration(milliseconds: 40);

    while (_isStreaming && _isNgConnected) {
      final DateTime frameStartTime = DateTime.now();
      _frameAckCompleter = Completer<void>();

      try {
        final Uint8List framePayload = encodeGridToNgFrame(_paintGrid);

        await UniversalBle.write(
          deviceId!,
          ngServiceUuid,
          ngWriteCharUuid,
          framePayload,
          withoutResponse: false,
        );

        await _frameAckCompleter!.future
            .timeout(const Duration(milliseconds: 150));
      } catch (e) {
        logger.w("Slow frame or missed notification timeout: $e");
      }

      final Duration elapsed = DateTime.now().difference(frameStartTime);
      if (elapsed < frameDuration) {
        await Future.delayed(frameDuration - elapsed);
      }
    }
  }

  /// Safely deactivates streaming and restores the badge memory
  Future<void> stopLiveStreaming() async {
    if (!_isStreaming) return;
    _isStreaming = false;

    _ngNotifySubscription?.cancel();
    _ngNotifySubscription = null;

    if (_ngDevice != null && _isNgConnected) {
      try {
        await UniversalBle.write(
          _ngDevice!.deviceId,
          ngServiceUuid,
          ngWriteCharUuid,
          Uint8List.fromList(NgCommand.leaveStreaming()),
          withoutResponse: false,
        );

        await UniversalBle.unsubscribe(
            _ngDevice!.deviceId, ngServiceUuid, ngNotifyCharUuid);
        logger.i(
            "Live Streaming stopped. The badge has returned to standard mode.");
      } catch (e) {
        logger.e("Error during streaming channel deactivation: $e");
      }
    }
    notifyListeners();
  }
}
