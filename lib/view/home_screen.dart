import 'dart:async';
import 'dart:math' as math;

import 'package:badgemagic/communication/completed_state.dart';
import 'package:badgemagic/communication/ng_command_state.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/storage/badge_loader_helper.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/image_utils.dart';
import 'package:badgemagic/others/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/main.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/badge_scan_provider.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/providers/next_gen_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/view/widgets/badge_clipart_picker.dart';
import 'package:badgemagic/view/widgets/badge_control_tab_bar.dart';
import 'package:badgemagic/view/widgets/badge_control_tab_view.dart';
import 'package:badgemagic/view/widgets/badge_text_input_field.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/animated_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

class HomeScreen extends StatefulWidget {
  final String? savedBadgeFilename;

  const HomeScreen({super.key, this.savedBadgeFilename});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  static const double _badgePreviewMaxWidth = 560;

  late final TabController _tabController;
  late final AnimationBadgeProvider animationProvider;
  late final SpeedDialProvider speedDialProvider;
  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  final ImageUtils imageUtils = ImageUtils();
  final InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  final TextEditingController inlineImageController =
      GetIt.instance.get<InlineImageProvider>().getController();

  final Converters _converters = Converters();

  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  bool isPrefixIconClicked = false;
  bool isDialInteracting = false;
  String previousText = '';
  String _cachedText = '';
  String errorVal = "";
  late final ScrollController _vectorScrollController;

  static const _textKey = 'badge_text';
  static const _speedKey = 'badge_speed';
  static const _transitionKey = 'badge_transition';
  static const _effectsKey = 'badge_effects';

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _vectorScrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    inlineImageController.addListener(handleTextChange);
    _setPortraitOrientation();
    animationProvider = context.read<AnimationBadgeProvider>();
    speedDialProvider = context.read<SpeedDialProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startImageCaching();
      await loadPreferences();

      inlineImageProvider.setContext(context);

      if (widget.savedBadgeFilename != null) {
        await _loadBadgeDataFromDisk(widget.savedBadgeFilename!);
      }

      inlineImageController.addListener(_debouncedSavePreferences);
      animationProvider.addListener(_debouncedSavePreferences);
      speedDialProvider.addListener(_debouncedSavePreferences);
    });
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final text = prefs.getString(_textKey);
    final speed = prefs.getInt(_speedKey);
    final transition = prefs.getInt(_transitionKey);
    final effects = prefs.getStringList(_effectsKey);
    if (text != null) {
      inlineImageController.text = text;
    }
    if (speed != null) {
      speedDialProvider.setDialValue(speed);
    }
    if (transition != null) {
      animationProvider.setAnimationMode(animationMap[transition]);
    }
    if (effects != null) {
      animationProvider.removeEffect(effectMap[0]);
      animationProvider.removeEffect(effectMap[1]);
      animationProvider.removeEffect(effectMap[2]);
      for (final effect in effects) {
        switch (effect) {
          case 'invert':
            animationProvider.addEffect(effectMap[0]);
            break;
          case 'flash':
            animationProvider.addEffect(effectMap[1]);
            break;
          case 'marquee':
            animationProvider.addEffect(effectMap[2]);
            break;
        }
      }
    }
    animationProvider.badgeAnimation(
      inlineImageController.text,
      _converters,
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textKey, inlineImageController.text);
    await prefs.setInt(
      _speedKey,
      speedDialProvider.getOuterValue(),
    );
    await prefs.setInt(
      _transitionKey,
      animationProvider.getAnimationIndex() ?? 0,
    );
    final effects = <String>[];
    if (animationProvider.isEffectActive(InvertLEDEffect())) {
      effects.add('invert');
    }
    if (animationProvider.isEffectActive(FlashEffect())) {
      effects.add('flash');
    }
    if (animationProvider.isEffectActive(MarqueeEffect())) {
      effects.add('marquee');
    }
    await prefs.setStringList(_effectsKey, effects);
  }

  Future<void> _loadBadgeDataFromDisk(String badgeFilename) async {
    try {
      final (badgeText, badgeData, savedData) =
          await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename);

      inlineImageController.text = badgeText;

      animationProvider.removeEffect(effectMap[0]);
      animationProvider.removeEffect(effectMap[1]);
      animationProvider.removeEffect(effectMap[2]);

      final message = badgeData.messages[0];
      if (message.flash) {
        animationProvider.addEffect(effectMap[1]);
      }
      if (message.marquee) {
        animationProvider.addEffect(effectMap[2]);
      }
      if (savedData != null &&
          savedData['messages'] is List &&
          (savedData['messages'] as List).isNotEmpty &&
          savedData['messages'][0]['invert'] == true) {
        animationProvider.addEffect(effectMap[0]);
      }

      int modeValue = BadgeLoaderHelper.parseAnimationMode(message.mode);
      animationProvider.setAnimationMode(animationMap[modeValue]);

      try {
        int speedDialValue = Speed.getIntValue(message.speed);
        speedDialProvider.setDialValue(speedDialValue);
      } catch (e) {
        speedDialProvider.setDialValue(1);
      }

      ToastUtils().showToast(
          "Editing badge: ${badgeFilename.substring(0, badgeFilename.length - 5)}");
    } catch (e, st) {
      debugPrint("Failed to load badge data: $e\n$st");
      ToastUtils().showToast("Failed to load badge data");
    }
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _startImageCaching() async {
    if (!inlineImageProvider.isCacheInitialized) {
      await inlineImageProvider.generateImageCache();
      setState(() {
        inlineImageProvider.isCacheInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _vectorScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    inlineImageController.removeListener(handleTextChange);
    inlineImageController.removeListener(_debouncedSavePreferences);
    animationProvider.removeListener(_debouncedSavePreferences);
    speedDialProvider.removeListener(_debouncedSavePreferences);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (inlineImageController.text.trim().isEmpty &&
          _cachedText.trim().isNotEmpty) {
        inlineImageController.text = _cachedText;
      }
      animationProvider.badgeAnimation(
        inlineImageController.text,
        _converters,
        animationProvider.isEffectActive(InvertLEDEffect()),
      );
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.paused) {
      _cachedText = inlineImageController.text;
      animationProvider.stopAnimation();
    } else if (state == AppLifecycleState.inactive) {
      animationProvider.stopAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);

    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (context, _, __) {
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
        return DefaultTabController(
          length: 4,
          child: CommonScaffold(
            index: 0,
            title: l10n.appTitle,
            scaffoldKey: const Key(homeScreenTitleKey),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, layoutConstraints) {
                  final bool isPhone = layoutConstraints.maxWidth < 600;

                  final badgePreview = Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _badgePreviewMaxWidth),
                      child: const AnimationBadge(),
                    ),
                  );
                  final textField = BadgeTextInputField(
                    controller: inlineImageController,
                    onPrefixToggle: () {
                      setState(() {
                        isPrefixIconClicked = !isPrefixIconClicked;
                      });
                    },
                    onFontChanged: () {
                      animationProvider.badgeAnimation(
                        inlineImageController.text,
                        _converters,
                        animationProvider.isEffectActive(InvertLEDEffect()),
                      );
                    },
                  );
                  final clipartPicker = BadgeClipartPicker(
                    visible: isPrefixIconClicked,
                    controller: _vectorScrollController,
                  );
                  final tabBar = BadgeControlTabBar(
                    controller: _tabController,
                  );
                  final dialTabView = BadgeControlTabView(
                    controller: _tabController,
                    onDialInteracting: (interacting) {
                      setState(() {
                        isDialInteracting = interacting;
                      });
                    },
                  );

                  Widget actionButton({
                    required String label,
                    required bool primary,
                    required Future<void> Function() onTap,
                  }) {
                    final double height = math.min(50.h, 54.0);
                    return SizedBox(
                      height: height,
                      child: FilledButton.tonal(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorSurfaceMuted,
                          foregroundColor: colorTextStrong,
                          elevation: 0,
                          textStyle: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(label),
                      ),
                    );
                  }

                  final actionButtons = Consumer<AnimationBadgeProvider>(
                      builder: (context, animationProvider, _) {
                    final isSpecial =
                        animationProvider.isSpecialAnimationSelected();
                    final device = animationProvider.ngDevice;

                    final scanProvider = context.watch<BadgeScanProvider>();
                    final isStreamingFeatureEnabled =
                        scanProvider.isStreamingEnabled;

                    Future<void> sendNgCmd(List<int> cmd, String msg) async {
                      if (device == null) return;
                      try {
                        final state =
                            NgCommandState(device: device, command: cmd);
                        final res = await state.process();
                        if (res != null) debugPrint(msg);
                      } catch (e) {
                        ToastUtils().showErrorToast(
                            e.toString().replaceAll("Exception: ", ""));
                      }
                    }

                    if (animationProvider.isNgConnected && device != null) {
                      return Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isStreamingFeatureEnabled)
                                  Card(
                                    color: animationProvider.isStreaming
                                        ? colorPrimary.withOpacity(0.05)
                                        : Colors.grey[100],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.r)),
                                    child: SwitchListTile(
                                      secondary: Icon(
                                        animationProvider.isStreaming
                                            ? Icons.live_tv
                                            : Icons.tv_off,
                                        color: animationProvider.isStreaming
                                            ? colorPrimary
                                            : mdGrey400,
                                      ),
                                      title: Text(
                                        l10n.liveMirroring,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      subtitle: Text(
                                        l10n.liveMirroringSubtitle,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      value: animationProvider.isStreaming,
                                      activeColor: colorPrimary,
                                      onChanged: (bool value) async {
                                        if (value) {
                                          await animationProvider
                                              .startLiveStreaming();
                                        } else {
                                          await animationProvider
                                              .stopLiveStreaming();
                                        }
                                      },
                                    ),
                                  ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red[400],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.all(12.w),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r)),
                                            ),
                                            onPressed: () async {
                                              await animationProvider
                                                  .stopLiveStreaming();
                                              await sendNgCmd(
                                                  NgCommand.powerOff(),
                                                  "Power Off sent");
                                              await UniversalBle.disconnect(
                                                  device.deviceId);
                                              animationProvider
                                                  .setNgConnected(false);
                                            },
                                            icon: const Icon(
                                                Icons.power_settings_new),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            textAlign: TextAlign.center,
                                            l10n.powerOff,
                                            style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.red[400]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            style: IconButton.styleFrom(
                                              backgroundColor: mdGrey400,
                                              foregroundColor: Colors.black,
                                              padding: EdgeInsets.all(12.w),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r)),
                                            ),
                                            onPressed: () async {
                                              await animationProvider
                                                  .stopLiveStreaming();
                                              await UniversalBle.disconnect(
                                                  device.deviceId);
                                              animationProvider
                                                  .setNgConnected(false);
                                              ToastUtils()
                                                  .showToast(l10n.disconnected);
                                            },
                                            icon: const Icon(
                                                Icons.bluetooth_disabled),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            textAlign: TextAlign.center,
                                            l10n.disconnect,
                                            style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            style: IconButton.styleFrom(
                                              foregroundColor:
                                                  animationProvider.isStreaming
                                                      ? Colors.red
                                                      : colorAccent,
                                              padding: EdgeInsets.all(12.w),
                                              side: BorderSide(
                                                color: animationProvider
                                                        .isStreaming
                                                    ? Colors.red
                                                    : colorAccent,
                                                width: 1.5.w,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r)),
                                            ),
                                            onPressed: () =>
                                                _showMoreOptionsBottomSheet(
                                                    context, device, sendNgCmd),
                                            icon: const Icon(Icons
                                                .drive_file_rename_outline),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            textAlign: TextAlign.center,
                                            l10n.renameBadge,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  animationProvider.isStreaming
                                                      ? Colors.red
                                                      : colorAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                StatefulBuilder(
                                  builder: (context, setSliderState) {
                                    return Row(
                                      children: [
                                        SizedBox(width: 8.w),
                                        Icon(Icons.wb_sunny,
                                            color: colorPrimary, size: 18.sp),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Slider(
                                            value: animationProvider
                                                .ngBrightness
                                                .toDouble(),
                                            min: 0,
                                            max: 3,
                                            divisions: 3,
                                            activeColor: colorPrimary,
                                            onChanged: (double newValue) {
                                              setSliderState(() {
                                                animationProvider
                                                    .setNgBrightness(
                                                        newValue.toInt());
                                              });
                                            },
                                            onChangeEnd: (double finalValue) =>
                                                sendNgCmd(
                                                    NgCommand.setBrightness(
                                                        finalValue.toInt()),
                                                    "Brightness updated"),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ));
                    }

                    return Row(
                      children: [
                        if (!isSpecial) ...[
                          Expanded(
                            child: actionButton(
                              label: l10n.saveButton,
                              primary: false,
                              onTap: _handleSave,
                            ),
                          ),
                          SizedBox(width: 24.w),
                        ],
                        Expanded(
                          child: actionButton(
                            label: l10n.transferButton,
                            primary: true,
                            onTap: () async {
                              final finalState = await _showBleTransferDialog(
                                  context, inlineImageProvider);
                              if (finalState != null &&
                                  finalState.isSuccess &&
                                  finalState.isNextGen) {
                                animationProvider.setNgConnected(true,
                                    manager: badgeData.deviceManager,
                                    device: badgeData
                                        .deviceManager?.connectedDevice);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  });

                  final buttonBar = Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                    child: actionButtons,
                  );

                  if (isPhone) {
                    return Column(
                      children: [
                        badgePreview,
                        textField,
                        clipartPicker,
                        tabBar,
                        Expanded(child: dialTabView),
                        buttonBar,
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: isDialInteracting
                              ? const NeverScrollableScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              badgePreview,
                              textField,
                              clipartPicker,
                              tabBar,
                              SizedBox(
                                height: (ScreenUtil().screenHeight * 0.33)
                                    .clamp(240.0, 380.0),
                                child: dialTabView,
                              ),
                            ],
                          ),
                        ),
                      ),
                      buttonBar,
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (inlineImageController.text.trim().isEmpty) {
      ToastUtils().showToast("Please enter a message");
      return;
    }

    if (widget.savedBadgeFilename != null) {
      SavedBadgeProvider savedBadgeProvider = SavedBadgeProvider();
      String baseFilename = widget.savedBadgeFilename!;
      if (baseFilename.endsWith('.json')) {
        baseFilename = baseFilename.substring(0, baseFilename.length - 5);
      }

      await savedBadgeProvider.updateBadgeData(
        baseFilename,
        inlineImageController.text,
        animationProvider.isEffectActive(FlashEffect()),
        animationProvider.isEffectActive(MarqueeEffect()),
        animationProvider.isEffectActive(InvertLEDEffect()),
        speedDialProvider.getOuterValue(),
        animationProvider.getAnimationIndex() ?? 1,
      );

      ToastUtils().showToast("Badge Updated Successfully");
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/savedBadge',
        (route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return SaveBadgeDialog(
            speed: speedDialProvider,
            animationProvider: animationProvider,
            textController: inlineImageController,
            isInverse: animationProvider.isEffectActive(InvertLEDEffect()),
          );
        },
      );
    }
  }

  Future<CompletedState?> _showBleTransferDialog(
      BuildContext context, InlineImageProvider inlineImageProvider) async {
    final bleDialogController = GetIt.instance<BleDialogController>();
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    bleDialogController.update(
        BleDialogStatus.searching, l10n.searchingDeviceBLE);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<BleDialogStatus>(
          valueListenable: bleDialogController.status,
          builder: (context, status, _) {
            return ValueListenableBuilder<double>(
              valueListenable: bleDialogController.progress,
              builder: (context, progress, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: bleDialogController.message,
                  builder: (context, message, _) {
                    return BleProgressDialog(
                      status: status,
                      progress: progress,
                      message: message,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    try {
      return await animationProvider.handleAnimationTransfer(
        badgeData: badgeData,
        inlineImageProvider: inlineImageProvider,
        speedDialProvider: speedDialProvider,
        flash: animationProvider.isEffectActive(FlashEffect()),
        marquee: animationProvider.isEffectActive(MarqueeEffect()),
        invert: animationProvider.isEffectActive(InvertLEDEffect()),
        context: context,
      );
    } catch (error) {
      bleDialogController.update(
        BleDialogStatus.error,
        "An unexpected error\noccurred.",
      );
      await Future.delayed(const Duration(milliseconds: 2000));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
    return null;
  }

  void _debouncedSavePreferences() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      savePreferences();
    });
  }

  void _showMoreOptionsBottomSheet(BuildContext context, BleDevice device,
      Function(List<int>, String) sendCmd) {
    final animProvider =
        Provider.of<AnimationBadgeProvider>(context, listen: false);
    final badgeScanProvider =
        Provider.of<BadgeScanProvider>(context, listen: false);
    final TextEditingController nameController =
        TextEditingController(text: animProvider.ngDeviceName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16.w,
              right: 16.w,
              top: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.renameBadge,
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              Text.rich(
                TextSpan(
                  text: l10n.currentName,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black),
                  children: [
                    TextSpan(
                      text: animProvider.ngDeviceName,
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: nameController,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: l10n.renameBadge,
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r))),
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      FocusScope.of(context).unfocus();

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return PopScope(
                            canPop: false,
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4.w),
                                    child: SizedBox(
                                      width: 40.w,
                                      height: 40.w,
                                      child: CircularProgressIndicator(
                                        color: colorPrimary,
                                        strokeWidth: 3.5.w,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Text(
                                    l10n.savingAndRebooting,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      try {
                        if (newName.isNotEmpty &&
                            newName != animProvider.ngDeviceName) {
                          await sendCmd(
                              NgCommand.setBleName(newName), l10n.nameApplied);
                          animProvider.setNgDeviceName(newName);

                          await sendCmd(NgCommand.saveCfg(), l10n.savedToFlash);
                          await sendCmd(NgCommand.powerOff(), l10n.turnOff);
                          await UniversalBle.disconnect(device.deviceId);

                          badgeScanProvider.addBadgeName(newName);

                          animProvider.setNgConnected(false);
                        }
                      } catch (e) {
                        debugPrint("Error during save sequence: $e");
                      } finally {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          Navigator.pop(context);
                        }
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: Text(l10n.saveFlashAndReboot),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  void handleTextChange() {
    if (animationProvider.isStreaming) {
      animationProvider.badgeAnimation(
        inlineImageController.text,
        _converters,
        animationProvider.isEffectActive(InvertLEDEffect()),
      );
      setState(() {});
      return;
    }

    if (animationProvider.isNgConnected) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        await animationProvider.sendDirectLegacyUpdate(
          text: inlineImageController.text,
          badgeData: badgeData,
          flash: animationProvider.isEffectActive(FlashEffect()),
          marquee: animationProvider.isEffectActive(MarqueeEffect()),
          invert: animationProvider.isEffectActive(InvertLEDEffect()),
          speed: speedDialProvider.getOuterValue(),
        );
      });
    }

    final currentText = inlineImageController.text;

    if (currentText != previousText) {
      if (animationProvider.isSpecialAnimationSelected() &&
          currentText.isNotEmpty) {
        animationProvider.resetToTextAnimation();
      }

      final selection = inlineImageController.selection;
      if (previousText.length > currentText.length) {
        final deletionIndex = selection.baseOffset;
        final regex = RegExp(r'<<\d+>>');
        final matches = regex.allMatches(previousText);

        bool placeholderDeleted = false;
        for (final match in matches) {
          if (deletionIndex > match.start && deletionIndex < match.end) {
            inlineImageController.text =
                previousText.replaceRange(match.start, match.end, '');
            inlineImageController.selection =
                TextSelection.collapsed(offset: match.start);
            placeholderDeleted = true;
            break;
          }
        }
        if (!placeholderDeleted) {
          previousText = inlineImageController.text;
        }
      } else {
        previousText = currentText;
      }

      animationProvider.badgeAnimation(
        inlineImageController.text,
        _converters,
        animationProvider.isEffectActive(InvertLEDEffect()),
      );

      setState(() {});
    }
  }

  @override
  bool get wantKeepAlive => true;
}
