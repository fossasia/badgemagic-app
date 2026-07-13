import 'dart:async';

import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/badge_loader_helper.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/main.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/transitiontab.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:universal_ble/universal_ble.dart';

import '../bademagic_module/bluetooth/ng_command_state.dart';
import '../providers/next_gen_provider.dart';

class HomeScreen extends StatefulWidget {
  final String? savedBadgeFilename;
  final int? initialSpeed;

  const HomeScreen({
    super.key,
    this.savedBadgeFilename,
    this.initialSpeed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
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
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  bool isPrefixIconClicked = false;
  bool isDialInteracting = false;
  int brightnessLevel = 1;
  String previousText = '';
  String _cachedText = '';
  String errorVal = "";
  late final ScrollController _vectorScrollController;
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

    if (widget.initialSpeed != null) {
      speedDialProvider.setDialValue(widget.initialSpeed!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      inlineImageProvider.setContext(context);

      if (widget.savedBadgeFilename != null) {
        await _loadBadgeDataFromDisk(widget.savedBadgeFilename!);
      }
    });
    _startImageCaching();
    _tabController = TabController(length: 4, vsync: this);
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

      ToastUtils().showToast(l10n.editingBadgeWithName(
          badgeFilename.substring(0, badgeFilename.length - 5)));
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
    _vectorScrollController.dispose();
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    inlineimagecontroller.removeListener(handleTextChange);
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
        return DefaultTabController(
          length: 4,
          child: CommonScaffold(
            index: 0,
            title: l10n.appTitle,
            scaffoldKey: const Key(homeScreenTitleKey),
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: isDialInteracting
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimationBadge(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15.w, vertical: 12.h),
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
                                  ? _getFontStyle(
                                          Provider.of<FontProvider>(context)
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
                                      isPrefixIconClicked =
                                          !isPrefixIconClicked;
                                    });
                                  },
                                  icon: const Icon(Icons.tag_faces_outlined),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 24,
                                ),
                                suffixIcon: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.280,
                                  ),
                                  padding:
                                      EdgeInsets.only(left: 8.w, right: 8.w),
                                  child: Consumer<FontProvider>(
                                    builder: (context, fontProvider, _) {
                                      return DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: fontProvider.selectedFont,
                                          icon: const SizedBox.shrink(),
                                          iconEnabledColor: mdGrey400,
                                          dropdownColor: Colors.white,
                                          itemHeight: 48,
                                          isExpanded: true,
                                          style: TextStyle(
                                            color: mdGrey400,
                                            fontSize: 12.sp,
                                          ),
                                          hint: Text(
                                            l10n.font,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: mdGrey400,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          padding: EdgeInsets.zero,
                                          items: [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                    vertical: 8.h),
                                                decoration: BoxDecoration(
                                                  color: fontProvider
                                                              .selectedFont ==
                                                          null
                                                      ? dividerColor
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  l10n.defaultFont,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: fontProvider
                                                                .selectedFont ==
                                                            null
                                                        ? colorAccent
                                                        : Colors.black,
                                                    fontWeight: fontProvider
                                                                .selectedFont ==
                                                            null
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                            ...fontProvider.availableFonts.map(
                                              (font) => DropdownMenuItem(
                                                value: font,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 8.h),
                                                  decoration: BoxDecoration(
                                                    color: fontProvider
                                                                .selectedFont ==
                                                            font
                                                        ? dividerColor
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    font,
                                                    style: _getFontStyle(font)
                                                        .copyWith(
                                                      color: fontProvider
                                                                  .selectedFont ==
                                                              font
                                                          ? colorAccent
                                                          : Colors.black,
                                                      fontWeight: fontProvider
                                                                  .selectedFont ==
                                                              font
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                          selectedItemBuilder: (context) {
                                            final List<String?> options = [
                                              null,
                                              ...fontProvider.availableFonts,
                                            ];
                                            return options.map((opt) {
                                              final String label =
                                                  opt ?? l10n.defaultFont;
                                              return Container(
                                                padding: EdgeInsets.only(
                                                  left: 4.w,
                                                  right: 4.w,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        label,
                                                        style: TextStyle(
                                                          color: mdGrey400,
                                                          fontSize: 12.sp,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                    SizedBox(width: 2.w),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      size: 18,
                                                      color: mdGrey400,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          },
                                          onChanged: (String? newFont) {
                                            fontProvider.changeFont(newFont);
                                            animationProvider.badgeAnimation(
                                              inlineimagecontroller.text,
                                              _converters,
                                              animationProvider.isEffectActive(
                                                  InvertLEDEffect()),
                                            );
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                          elevation: 2,
                                          isDense: true,
                                          menuMaxHeight: 300.h,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Visibility(
                            visible: isPrefixIconClicked,
                            child: Container(
                              height: isPrefixIconClicked ? 170.h : 0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                color: Colors.grey[200],
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 15.w, vertical: 8.h),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 10.w),
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
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: TabBar(
                            isScrollable: false,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: mdGrey400,
                            indicatorColor: colorPrimary,
                            controller: _tabController,
                            splashFactory: InkRipple.splashFactory,
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>(
                              (states) => states.contains(WidgetState.pressed)
                                  ? dividerColor
                                  : null,
                            ),
                            labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
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
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Consumer<AnimationBadgeProvider>(
                              builder: (context, animProvider, _) {
                                final availableHeight =
                                    animProvider.isNgConnected
                                        ? 0.3 * ScreenUtil().screenHeight
                                        : 0.5 * ScreenUtil().screenHeight;

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: animProvider.isNgConnected
                                        ? 170.h
                                        : 220.h,
                                    maxHeight: availableHeight,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: animProvider.isNgConnected
                                            ? 2.h
                                            : 12.h),
                                    child: TabBarView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      controller: _tabController,
                                      children: [
                                        GestureDetector(
                                          onPanDown: (_) => setState(
                                              () => isDialInteracting = true),
                                          onPanCancel: () => setState(
                                              () => isDialInteracting = false),
                                          onPanEnd: (_) => setState(
                                              () => isDialInteracting = false),
                                          child: Align(
                                            alignment:
                                                animProvider.isNgConnected
                                                    ? Alignment.topCenter
                                                    : Alignment.center,
                                            child: RadialDial(),
                                          ),
                                        ),
                                        const TransitionTab(),
                                        const EffectTab(),
                                        const AnimationTab(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Consumer<AnimationBadgeProvider>(
                          builder: (context, animationProvider, _) {
                        final isSpecial =
                            animationProvider.isSpecialAnimationSelected();
                        final device = animationProvider.ngDevice;

                        Future<void> sendNgCmd(
                            List<int> cmd, String msg) async {
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
                                                  backgroundColor:
                                                      Colors.red[400],
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.all(12.w),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.r)),
                                                ),
                                                onPressed: () async {
                                                  await animationProvider
                                                      .stopLiveStreaming(); // Sicurezza se era attivo il mirroring
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
                                                  ToastUtils().showToast(
                                                      l10n.disconnected);
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
                                                      animationProvider
                                                              .isStreaming
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
                                                        context,
                                                        device,
                                                        sendNgCmd),
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
                                                  color: animationProvider
                                                          .isStreaming
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
                                                color: colorPrimary,
                                                size: 18.sp),
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
                                                onChangeEnd: (double
                                                        finalValue) =>
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
                                child: GestureDetector(
                                  onTap: () async {
                                    if (inlineimagecontroller.text
                                        .trim()
                                        .isEmpty) {
                                      ToastUtils()
                                          .showToast(l10n.pleaseEnterMessage);
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
                                        animationProvider.getAnimationIndex() ??
                                            1,
                                      );

                                      ToastUtils().showToast(
                                          l10n.badgeUpdatedSuccessfully);
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
                                            animationProvider:
                                                animationProvider,
                                            textController:
                                                inlineimagecontroller,
                                            isInverse: animationProvider
                                                .isEffectActive(
                                                    InvertLEDEffect()),
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 32.h,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.r),
                                      color: mdGrey400,
                                    ),
                                    child: Text(l10n.saveButton),
                                  ),
                                ),
                              ),
                              SizedBox(width: 24.w),
                            ],
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final finalState = await animationProvider
                                      .handleAnimationTransfer(
                                    badgeData: badgeData,
                                    inlineImageProvider: inlineImageProvider,
                                    speedDialProvider: speedDialProvider,
                                    flash: animationProvider
                                        .isEffectActive(FlashEffect()),
                                    marquee: animationProvider
                                        .isEffectActive(MarqueeEffect()),
                                    invert: animationProvider
                                        .isEffectActive(InvertLEDEffect()),
                                    context: context,
                                  );

                                  if (finalState != null &&
                                      finalState.isSuccess &&
                                      finalState.isNextGen) {
                                    animationProvider.setNgConnected(true,
                                        manager: badgeData.deviceManager,
                                        device: badgeData
                                            .deviceManager?.connectedDevice);
                                  }
                                },
                                child: Container(
                                  height: 32.h,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: mdGrey400,
                                  ),
                                  child: Text(l10n.transferButton),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context, BleDevice device,
      Function(List<int>, String) sendCmd) {
    final animProvider =
        Provider.of<AnimationBadgeProvider>(context, listen: false);
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
        inlineimagecontroller.text,
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
          text: inlineimagecontroller.text,
          badgeData: badgeData,
          flash: animationProvider.isEffectActive(FlashEffect()),
          marquee: animationProvider.isEffectActive(MarqueeEffect()),
          invert: animationProvider.isEffectActive(InvertLEDEffect()),
          speed: speedDialProvider.getOuterValue(),
        );
      });
    }

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
