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
import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';
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

  bool isPrefixIconClicked = false;
  bool isDialInteracting = false;
  String previousText = '';
  String _cachedText = '';
  String errorVal = "";
  late final ScrollController _vectorScrollController;

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
    _vectorScrollController.dispose();
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
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
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
                                            'Font',
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
                                                  'Default',
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
                                                  opt ?? 'Default';
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
                            final availableHeight =
                                0.5 * ScreenUtil().screenHeight;

                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: 220.h,
                                maxHeight: availableHeight,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 12.h),
                                child: TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  controller: _tabController,
                                  children: [
                                    GestureDetector(
                                      onPanDown: (_) => setState(
                                          () => isDialInteracting = true),
                                      onPanCancel: () => setState(
                                          () => isDialInteracting = false),
                                      onPanEnd: (_) => setState(
                                          () => isDialInteracting = false),
                                      child: RadialDial(),
                                    ),
                                    const TransitionTab(),
                                    const EffectTab(),
                                    const AnimationTab(),
                                  ],
                                ),
                              ),
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
                                        animationProvider.getAnimationIndex() ??
                                            1,
                                      );

                                      ToastUtils().showToast(
                                          "Badge Updated Successfully");
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
                                onTap: () => _showBleTransferDialog(
                                    context, inlineImageProvider),
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

  void _showBleTransferDialog(
      BuildContext context, InlineImageProvider inlineImageProvider) {
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

    animationProvider
        .handleAnimationTransfer(
      badgeData: badgeData,
      inlineImageProvider: inlineImageProvider,
      speedDialProvider: speedDialProvider,
      flash: animationProvider.isEffectActive(FlashEffect()),
      marquee: animationProvider.isEffectActive(MarqueeEffect()),
      invert: animationProvider.isEffectActive(InvertLEDEffect()),
      context: context,
    )
        .catchError((error) {
      bleDialogController.update(
        BleDialogStatus.error,
        "An unexpected error\noccurred.",
      );
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (context.mounted) Navigator.of(context).pop();
      });
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
