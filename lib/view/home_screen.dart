import 'dart:async';
import 'dart:math' as math;

import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/badge_loader_helper.dart';
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
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/view/widgets/special_text_field.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/home_screen_tabs.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speed_dial.dart';
import 'package:badgemagic/view/widgets/transition_tab.dart';
import 'package:badgemagic/view/widgets/vector_view.dart';
import 'package:badgemagic/view/widgets/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController inlineimagecontroller =
      GetIt.instance.get<InlineImageProvider>().getController();

  final Converters _converters = Converters();

  bool isPrefixIconClicked = false;
  String previousText = '';
  String _cachedText = '';
  String errorVal = "";
  late final ScrollController _vectorScrollController;

  //Shared preferences keys
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
    inlineimagecontroller.addListener(handleTextChange);
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

      inlineimagecontroller.addListener(_debouncedSavePreferences);
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
      inlineimagecontroller.text = text;
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
      inlineimagecontroller.text,
      _converters,
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textKey, inlineimagecontroller.text);
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

      inlineimagecontroller.text = badgeText;

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

  TextStyle _getFontStyle(String fontName) {
    const baseStyle = TextStyle(fontSize: 12);
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Open Sans':
        return GoogleFonts.openSans(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lato':
        return GoogleFonts.lato(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Poppins':
        return GoogleFonts.poppins(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Montserrat':
        return GoogleFonts.montserrat(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Orbitron':
        return GoogleFonts.orbitron(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lexend':
        return GoogleFonts.lexend(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      default:
        return baseStyle;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _vectorScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    inlineimagecontroller.removeListener(handleTextChange);
    inlineimagecontroller.removeListener(_debouncedSavePreferences);
    animationProvider.removeListener(_debouncedSavePreferences);
    speedDialProvider.removeListener(_debouncedSavePreferences);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (inlineimagecontroller.text.trim().isEmpty &&
          _cachedText.trim().isNotEmpty) {
        inlineimagecontroller.text = _cachedText;
      }
      animationProvider.badgeAnimation(
        inlineimagecontroller.text,
        _converters,
        animationProvider.isEffectActive(InvertLEDEffect()),
      );
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.paused) {
      _cachedText = inlineimagecontroller.text;
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
                  final badgePreview = Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _badgePreviewMaxWidth),
                      child: AnimationBadge(),
                    ),
                  );
                  final textField = Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                    child: Material(
                      color: drawerHeaderTitle,
                      borderRadius: BorderRadius.circular(10.r),
                      elevation: 4,
                      child: ExtendedTextField(
                        controller: inlineimagecontroller,
                        specialTextSpanBuilder: ImageBuilder(),
                        style: Provider.of<FontProvider>(context)
                                    .selectedFont !=
                                null
                            ? _getFontStyle(Provider.of<FontProvider>(context)
                                    .selectedFont!)
                                .copyWith(fontSize: 14)
                            : const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: colorPrimary),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isPrefixIconClicked = !isPrefixIconClicked;
                              });
                            },
                            icon: const Icon(Icons.tag_faces_outlined),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 24,
                          ),
                          suffixIcon: Container(
                            constraints: BoxConstraints(
                              maxWidth: math.min(
                                  MediaQuery.of(context).size.width * 0.280,
                                  200.0),
                            ),
                            padding: EdgeInsets.only(left: 8.w, right: 8.w),
                            child: Consumer<FontProvider>(
                              builder: (context, fontProvider, _) {
                                return MenuAnchor(
                                  alignmentOffset: const Offset(0, 8),
                                  style: MenuStyle(
                                    alignment: AlignmentDirectional.bottomEnd,
                                    minimumSize: const WidgetStatePropertyAll(
                                        Size(180, 0)),
                                    backgroundColor:
                                        const WidgetStatePropertyAll(
                                            Colors.white),
                                    surfaceTintColor:
                                        const WidgetStatePropertyAll(
                                            Colors.white),
                                    elevation: const WidgetStatePropertyAll(6),
                                    padding: WidgetStatePropertyAll(
                                      EdgeInsets.symmetric(vertical: 6.h),
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                    ),
                                  ),
                                  menuChildren: <String?>[
                                    null,
                                    ...fontProvider.availableFonts,
                                  ].map((opt) {
                                    final label = opt ?? 'Default';
                                    final selected =
                                        fontProvider.selectedFont == opt;
                                    return MenuItemButton(
                                      onPressed: () {
                                        fontProvider.changeFont(opt);
                                        animationProvider.badgeAnimation(
                                          inlineimagecontroller.text,
                                          _converters,
                                          animationProvider.isEffectActive(
                                              InvertLEDEffect()),
                                        );
                                      },
                                      trailingIcon: selected
                                          ? Icon(Icons.check,
                                              size: 18, color: colorPrimary)
                                          : const SizedBox(width: 18),
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 4.h),
                                        child: Text(
                                          label,
                                          style: (opt == null
                                                  ? const TextStyle()
                                                  : _getFontStyle(opt))
                                              .copyWith(
                                            fontSize: 14,
                                            color: selected
                                                ? colorPrimary
                                                : Colors.black87,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  builder: (context, controller, child) {
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(8.r),
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        controller.isOpen
                                            ? controller.close()
                                            : controller.open();
                                      },
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6.h),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                fontProvider.selectedFont ??
                                                    'Default',
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  color: mdGrey400,
                                                  fontSize: 12.sp,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 20,
                                              color: mdGrey400,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  final clipartPicker = AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Visibility(
                      visible: isPrefixIconClicked,
                      child: Container(
                        height: isPrefixIconClicked ? 200.h : 0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: Colors.grey[200],
                        ),
                        margin: EdgeInsets.symmetric(
                            horizontal: 15.w, vertical: 8.h),
                        padding:
                            EdgeInsets.symmetric(vertical: 10.h, horizontal: 8),
                        child: Scrollbar(
                          controller: _vectorScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 4.0,
                          radius: const Radius.circular(10),
                          child: VectorGridView(
                              controller: _vectorScrollController),
                        ),
                      ),
                    ),
                  );
                  final tabBar = Container(
                    margin: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 4.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: TabBar(
                      isScrollable: false,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      splashBorderRadius: BorderRadius.circular(30.r),
                      labelStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: mdGrey400,
                      controller: _tabController,
                      splashFactory: InkRipple.splashFactory,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: layoutConstraints.maxWidth < 600 ? 1.h : 2.h,
                      ),
                      tabs: [
                        Tab(
                          key: const ValueKey('tab_speed'),
                          text: l10n.speedTitle,
                        ),
                        Tab(
                          key: const ValueKey('tab_transition'),
                          text: l10n.transitionTitle,
                        ),
                        Tab(
                          key: const ValueKey('tab_effects'),
                          text: l10n.effectsTitle,
                        ),
                        Tab(
                          key: const ValueKey('tab_animation'),
                          text: l10n.animation,
                        ),
                      ],
                    ),
                  );
                  final dialTabView = Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        RadialDial(),
                        const TransitionTab(),
                        const EffectTab(),
                        const AnimationTab(),
                      ],
                    ),
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
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
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
                              onTap: () async {
                                if (inlineimagecontroller.text.trim().isEmpty) {
                                  ToastUtils()
                                      .showToast("Please enter a message");
                                  return;
                                }

                                if (widget.savedBadgeFilename != null) {
                                  SavedBadgeProvider savedBadgeProvider =
                                      SavedBadgeProvider();
                                  String baseFilename =
                                      widget.savedBadgeFilename!;
                                  if (baseFilename.endsWith('.json')) {
                                    baseFilename = baseFilename.substring(
                                        0, baseFilename.length - 5);
                                  }

                                  await savedBadgeProvider.updateBadgeData(
                                    baseFilename,
                                    inlineimagecontroller.text,
                                    animationProvider
                                        .isEffectActive(FlashEffect()),
                                    animationProvider
                                        .isEffectActive(MarqueeEffect()),
                                    animationProvider
                                        .isEffectActive(InvertLEDEffect()),
                                    speedDialProvider.getOuterValue(),
                                    animationProvider.getAnimationIndex() ?? 1,
                                  );

                                  ToastUtils()
                                      .showToast("Badge Updated Successfully");
                                  if (!context.mounted) return;
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
                                        textController: inlineimagecontroller,
                                        isInverse: animationProvider
                                            .isEffectActive(InvertLEDEffect()),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 24.w),
                        ],
                        Expanded(
                          child: actionButton(
                            label: l10n.transferButton,
                            primary: true,
                            onTap: () async {
                              _showBleTransferDialog(
                                  context, inlineImageProvider);
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
                          color: Colors.white,
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

                  final bool isPhone = layoutConstraints.maxWidth < 600;

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

  void _debouncedSavePreferences() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      savePreferences();
    });
  }

  void handleTextChange() {
    final currentText = inlineimagecontroller.text;

    if (currentText != previousText) {
      if (animationProvider.isSpecialAnimationSelected() &&
          currentText.isNotEmpty) {
        animationProvider.resetToTextAnimation();
      }

      final selection = inlineimagecontroller.selection;
      if (previousText.length > currentText.length) {
        final deletionIndex = selection.baseOffset;
        final regex = RegExp(r'<<\d+>>');
        final matches = regex.allMatches(previousText);

        bool placeholderDeleted = false;
        for (final match in matches) {
          if (deletionIndex > match.start && deletionIndex < match.end) {
            inlineimagecontroller.text =
                previousText.replaceRange(match.start, match.end, '');
            inlineimagecontroller.selection =
                TextSelection.collapsed(offset: match.start);
            placeholderDeleted = true;
            break;
          }
        }
        if (!placeholderDeleted) {
          previousText = inlineimagecontroller.text;
        }
      } else {
        previousText = currentText;
      }

      animationProvider.badgeAnimation(
        inlineimagecontroller.text,
        _converters,
        animationProvider.isEffectActive(InvertLEDEffect()),
      );

      setState(() {});
    }
  }

  @override
  bool get wantKeepAlive => true;
}
