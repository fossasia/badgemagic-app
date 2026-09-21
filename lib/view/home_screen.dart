import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:badgemagic/communication/completed_state.dart';
import 'package:badgemagic/communication/ng_command_state.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/storage/badge_loader_helper.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/globals.dart';
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
import 'package:badgemagic/providers/firmware_update.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/providers/next_gen_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/view/widgets/badge_clipart_picker.dart';
import 'package:badgemagic/view/widgets/vector_view.dart';
import 'package:badgemagic/view/widgets/badge_control_tab_bar.dart';
import 'package:badgemagic/view/widgets/gifview.dart';
import 'package:badgemagic/view/widgets/badge_control_tab_view.dart';
import 'package:badgemagic/view/widgets/badge_text_input_field.dart';
import 'package:badgemagic/view/widgets/firmware_update_dialog.dart';
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

import '../providers/usb_transfer_provider.dart';

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

  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  final Converters _converters = Converters();
  final GlobalKey _textFieldKey = GlobalKey();

  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  bool isPrefixIconClicked = false;
  bool isDialInteracting = false;
  bool _showGifs = false;
  String? _selectedGifPath;
  String previousText = '';
  String _cachedText = '';
  String errorVal = "";
  late final ScrollController _vectorScrollController;
  late final ScrollController _gifScrollController;

  static const _textKey = 'badge_text';
  static const _speedKey = 'badge_speed';
  static const _transitionKey = 'badge_transition';
  static const _effectsKey = 'badge_effects';
  bool _hasCheckedThisSession = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _vectorScrollController = ScrollController();
    _gifScrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    inlineImageController.addListener(handleTextChange);
    _setPortraitOrientation();
    animationProvider = context.read<AnimationBadgeProvider>();
    speedDialProvider = context.read<SpeedDialProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startImageCaching();
      await loadPreferences();

      final usbPrefs = await SharedPreferences.getInstance();
      if ((usbPrefs.getBool('usb_transfer_enabled') ?? !Platform.isLinux) &&
          mounted) {
        await context.read<UsbTransferProvider>().startUsbMonitoring();
      }

      if (!mounted) return;
      inlineImageProvider.setContext(context);

      if (widget.savedBadgeFilename != null) {
        await _loadBadgeDataFromDisk(widget.savedBadgeFilename!);
      }

      inlineImageController.addListener(_debouncedSavePreferences);
      animationProvider.addListener(_debouncedSavePreferences);
      speedDialProvider.addListener(_debouncedSavePreferences);
    });
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initiateFirmwareCheck();
    });
  }

  Future<void> _initiateFirmwareCheck() async {
    final flasher = WchUsbIspFlasher();
    final updateInfo = await flasher.checkForUpdates();
    final prefs = await SharedPreferences.getInstance();
    var version = updateInfo?['version'];
    final bool shouldSkip =
        prefs.getBool('skip_firmware_version_$version') ?? false;
    bool autoCheck = await autocheckFirmwareUpdates();

    if (autoCheck &&
        updateInfo != null &&
        mounted &&
        !shouldSkip &&
        !_hasCheckedThisSession) {
      _hasCheckedThisSession = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return FirmwareUpdateDialog(
            version: updateInfo['version']!,
            date: updateInfo['date']!,
            releaseAssets: updateInfo['assets'] ?? [],
          );
        },
      );
    }
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
          "${l10n.editingBadge}: ${badgeFilename.substring(0, badgeFilename.length - 5)}");
    } catch (e, st) {
      debugPrint("Failed to load badge data: $e\n$st");
      ToastUtils().showToast(l10n.failedToLoadBadgeData);
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
    _gifScrollController.dispose();
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

  Widget _buildClipartToggle() {
    Widget segment(
        String label, IconData icon, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              color: selected ? colorPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 15.sp, color: selected ? Colors.white : mdGrey400),
                SizedBox(width: 5.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : mdGrey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          segment('Cliparts', Icons.emoji_symbols_rounded, !_showGifs, () {
            if (_showGifs) setState(() => _showGifs = false);
          }),
          segment('GIFs', Icons.gif_box_rounded, _showGifs, () {
            if (!_showGifs) setState(() => _showGifs = true);
          }),
        ],
      ),
    );
  }

  Future<void> _handleGifSelected(String assetPath) async {
    if (_selectedGifPath == assetPath && animationProvider.isGifActive) {
      animationProvider.stopAllAnimations();
      animationProvider.badgeAnimation(
        inlineImageController.text,
        _converters,
        animationProvider.isEffectActive(InvertLEDEffect()),
      );
      setState(() => _selectedGifPath = null);
      return;
    }
    try {
      final ByteData bytes = await rootBundle.load(assetPath);
      final frames = imageUtils.decodeGifFramesToBool(
        bytes.buffer.asUint8List(),
      );
      if (frames.isEmpty) return;
      animationProvider.playGif(frames);
      setState(() => _selectedGifPath = assetPath);
    } catch (e) {
      debugPrint('Failed to load GIF: $assetPath -> $e');
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
                  final bool isHeightConstrained =
                      layoutConstraints.maxHeight < 650;

                  final badgePreview = Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _badgePreviewMaxWidth),
                      child: const AnimationBadge(),
                    ),
                  );
                  final textField = BadgeTextInputField(
                    key: _textFieldKey,
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
                  final clipartPicker = AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Visibility(
                      visible: isPrefixIconClicked,
                      child: Container(
                        height: isPrefixIconClicked ? 225.h : 0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: colorSurfaceMuted,
                        ),
                        margin: EdgeInsets.symmetric(
                            horizontal: 15.w, vertical: 8.h),
                        padding: EdgeInsets.symmetric(
                            vertical: 10.h, horizontal: 10.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildClipartToggle(),
                            SizedBox(height: 6.h),
                            Expanded(
                              child: _showGifs
                                  ? Scrollbar(
                                      controller: _gifScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      thickness: 4.0,
                                      radius: const Radius.circular(10),
                                      child: GifGridView(
                                        controller: _gifScrollController,
                                        onGifSelected: _handleGifSelected,
                                        selectedPath: _selectedGifPath,
                                      ),
                                    )
                                  : Scrollbar(
                                      controller: _vectorScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      thickness: 4.0,
                                      radius: const Radius.circular(10),
                                      child: VectorGridView(
                                          controller: _vectorScrollController),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final isUsbEnabled =
                                  prefs.getBool('usb_transfer_enabled') ??
                                      !Platform.isLinux;

                              if (!context.mounted) return;

                              if (isUsbEnabled) {
                                _showTransferBottomSheet(context);
                              } else {
                                _showBleTransferDialog(
                                    context, inlineImageProvider);
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

                  if (isPhone && !isHeightConstrained) {
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
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    if (inlineImageController.text.trim().isEmpty) {
      ToastUtils().showToast(l10n.pleaseEnterMessage);
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

      ToastUtils().showToast(l10n.badgeUpdatedSuccessfully);
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
        l10n.unknownError,
      );
      await Future.delayed(const Duration(milliseconds: 2000));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
    return null;
  }

  Future<void> _sendViaUsb(UsbTransferProvider usbProvider) async {
    final int aniIndex = animationProvider.getAnimationIndex() ?? 0;

    List<int>? generatedData;
    if (aniIndex >= 9) {
      generatedData = await animationProvider.generateAnimationUsbPayload(
        badgeData,
        speedDialProvider.getOuterValue(),
      );
      if (generatedData == null || generatedData.isEmpty) {
        ToastUtils().showErrorToast("Could not generate animation data.");
        return;
      }
    } else {
      generatedData = await animationProvider.generateLegacyPayload(
        text: inlineImageController.text,
        flash: animationProvider.isEffectActive(FlashEffect()),
        marquee: animationProvider.isEffectActive(MarqueeEffect()),
        invert: animationProvider.isEffectActive(InvertLEDEffect()),
        speed: speedDialProvider.getOuterValue(),
        badgeData: badgeData,
      );
      if (generatedData == null || generatedData.isEmpty) {
        ToastUtils().showErrorToast("Please enter a message to transfer.");
        return;
      }
    }

    try {
      ToastUtils().showToast("Searching for USB badge...");
      bool connected = false;
      const int maxAttempts = 40;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        connected = await usbProvider.connectHid(silent: true);
        if (connected) break;
        if (attempt < maxAttempts - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      if (!connected) {
        ToastUtils().showErrorToast(
            "No USB badge found. Check the cable and try again.");
        return;
      }

      final success = await usbProvider.writeBytes(generatedData, silent: true);
      if (success) {
        ToastUtils().showToast("USB transfer success!");
      } else {
        ToastUtils().showErrorToast("USB transfer failed. Try again.");
      }
    } catch (e) {
      debugPrint("Error USB: $e");
      ToastUtils().showErrorToast("Error USB transfer");
    }
  }

  void _showTransferBottomSheet(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 20.h,
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20.h,
                left: 16.w,
                right: 16.w,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Choose Transfer Method",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Consumer<UsbTransferProvider>(
                    builder: (context, usbProvider, _) {
                      Widget option({
                        required String label,
                        required IconData icon,
                        required Color color,
                        required Future<void> Function() onTap,
                      }) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: onTap,
                              child: Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.1),
                                  border: Border.all(color: color, width: 2),
                                ),
                                child: Icon(icon, size: 24.w, color: color),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        );
                      }

                      final bool supportsUsb = Platform.isAndroid ||
                          Platform.isWindows ||
                          Platform.isLinux ||
                          Platform.isMacOS;

                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24.w,
                        runSpacing: 16.h,
                        children: [
                          option(
                            label: "Bluetooth",
                            icon: Icons.bluetooth,
                            color: colorAccent,
                            onTap: () async {
                              Navigator.pop(bottomSheetContext);
                              _showBleTransferDialog(
                                  context, inlineImageProvider);
                            },
                          ),
                          if (supportsUsb)
                            option(
                              label: "USB HID",
                              icon: Icons.usb,
                              color: colorAccent,
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                await _sendViaUsb(usbProvider);
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
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
      if (currentText.isNotEmpty && _selectedGifPath != null) {
        _selectedGifPath = null;
      }
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
