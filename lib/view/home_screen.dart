import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

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
import 'package:badgemagic/providers/inline_image_provider.dart';
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

  final Converters _converters = Converters();

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

      final usbPrefs = await SharedPreferences.getInstance();
      if ((usbPrefs.getBool('usb_transfer_enabled') ?? !Platform.isLinux) &&
          mounted) {
        await context.read<UsbTransferProvider>().startUsbMonitoring();
      }

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
                      child: AnimationBadge(),
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
                    isNarrow: isPhone,
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
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  });

                  Widget cardWrap(Widget child) => Container(
                        margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: colorSurface,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: child,
                      );

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
                        Expanded(
                          child: cardWrap(
                            Column(
                              children: [
                                tabBar,
                                Expanded(child: dialTabView),
                              ],
                            ),
                          ),
                        ),
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
                              cardWrap(
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    tabBar,
                                    SizedBox(
                                      height: (ScreenUtil().screenHeight * 0.33)
                                          .clamp(240.0, 380.0),
                                      child: dialTabView,
                                    ),
                                  ],
                                ),
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

  Future<void> _showBleTransferDialog(
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
      await animationProvider.handleAnimationTransfer(
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

  void handleTextChange() {
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
