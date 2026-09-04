import 'dart:async';

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
import 'package:badgemagic/providers/firmware_update.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/view/widgets/badge_action_buttons.dart';
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
                  final actionButtons = BadgeActionButtons(
                    onSave: _handleSave,
                    onTransfer: () =>
                        _showBleTransferDialog(context, inlineImageProvider),
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
        l10n.unknownError,
      );
      await Future.delayed(const Duration(milliseconds: 2000));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
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
