import 'dart:async';

import 'package:badgemagic/bademagic_module/utils/badge_loader_helper.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';

import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
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
import 'package:badgemagic/view/widgets/transitiontab.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  // Add parameters for saved badge data when editing
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
  final AnimationBadgeProvider animationProvider = AnimationBadgeProvider();
  late SpeedDialProvider speedDialProvider;
  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  final ImageUtils imageUtils = ImageUtils();
  final InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  final TextEditingController inlineimagecontroller =
      GetIt.instance.get<InlineImageProvider>().getController();

  bool isPrefixIconClicked = false;
  bool isDialInteracting = false;
  String previousText = '';
  String _cachedText = '';
  String errorVal = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    inlineimagecontroller.addListener(handleTextChange);
    _setPortraitOrientation();
    speedDialProvider = SpeedDialProvider(animationProvider);

    // If initialSpeed is provided, set it immediately
    if (widget.initialSpeed != null) {
      speedDialProvider.setDialValue(widget.initialSpeed!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      inlineImageProvider.setContext(context);

      // Apply saved badge data if we're editing a saved badge
      if (widget.savedBadgeFilename != null) {
        await _loadBadgeDataFromDisk(widget.savedBadgeFilename!);
      }
    });
    _startImageCaching();
    _tabController = TabController(length: 4, vsync: this);
  }

  // Loads badge data from disk and populates controllers/providers for editing
  Future<void> _loadBadgeDataFromDisk(String badgeFilename) async {
    try {
      final (badgeText, badgeData, savedData) =
          await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename);

      // Set the text in the controller
      inlineimagecontroller.text = badgeText;

      // Set animation effects
      animationProvider.removeEffect(effectMap[0]); // Invert
      animationProvider.removeEffect(effectMap[1]); // Flash
      animationProvider.removeEffect(effectMap[2]); // Marquee

      final message = badgeData.messages[0];
      if (message.flash) {
        animationProvider.addEffect(effectMap[1]);
      }
      if (message.marquee) {
        animationProvider.addEffect(effectMap[2]);
      }
      if (savedData != null &&
          savedData.containsKey('invert') &&
          savedData['invert'] == true) {
        animationProvider.addEffect(effectMap[0]);
      }

      // Set animation mode
      int modeValue = BadgeLoaderHelper.parseAnimationMode(message.mode);
      animationProvider.setAnimationMode(animationMap[modeValue]);

      // Set speed
      try {
        int speedDialValue = Speed.getIntValue(message.speed);
        speedDialProvider.setDialValue(speedDialValue);
      } catch (e) {
        speedDialProvider.setDialValue(1);
      }

      ToastUtils().showToast(
          "Editing badge: ${badgeFilename.substring(0, badgeFilename.length - 5)}");
    } catch (e) {
      print("Failed to load badge data: $e");
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
    WidgetsBinding.instance.removeObserver(this);
    inlineimagecontroller.removeListener(handleTextChange);
    inlineimagecontroller.removeListener(_controllerListner);
    animationProvider.stopAnimation();
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
        Converters(),
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
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AnimationBadgeProvider>(
              create: (context) => animationProvider,
            ),
            ChangeNotifierProvider<SpeedDialProvider>(
              create: (context) {
                inlineImageProvider
                    .getController()
                    .addListener(_controllerListner);
                return speedDialProvider;
              },
            ),
          ],
          child: DefaultTabController(
            length: 4,
            child: CommonScaffold(
              index: 0,
              title: l10n.appTitle,
              body: SafeArea(
                child: Stack(
                  children: [
                    // Scrollable content
                    SingleChildScrollView(
                      physics: isDialInteracting
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimationBadge(),
                          Container(
                            margin: EdgeInsets.all(15.w),
                            child: Material(
                              color: drawerHeaderTitle,
                              borderRadius: BorderRadius.circular(10.r),
                              elevation: 4,
                              child: ExtendedTextField(
                                onChanged: (value) {},
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
                                  prefixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isPrefixIconClicked =
                                            !isPrefixIconClicked;
                                      });
                                    },
                                    icon: const Icon(Icons.tag_faces_outlined),
                                  ),
                                  suffixIcon: Padding(
                                    padding: EdgeInsets.only(right: 8.w),
                                    child: Consumer<FontProvider>(
                                      builder: (context, fontProvider, _) {
                                        return DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: fontProvider.selectedFont,
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            hint: Text(
                                              'Font',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: null,
                                                child: Text(
                                                  'Default Font',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              ...fontProvider.availableFonts
                                                  .map((font) =>
                                                      DropdownMenuItem(
                                                        value: font,
                                                        child: Text(
                                                          font,
                                                          style: _getFontStyle(
                                                              font),
                                                        ),
                                                      ))
                                            ],
                                            onChanged: (String? newFont) {
                                              fontProvider.changeFont(newFont);
                                              animationProvider.badgeAnimation(
                                                inlineimagecontroller.text,
                                                Converters(),
                                                animationProvider
                                                    .isEffectActive(
                                                        InvertLEDEffect()),
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            elevation: 2,
                                            isDense: true,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                              visible: isPrefixIconClicked,
                              child: Container(
                                  height: 170.h,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.r),
                                      color: Colors.grey[200]),
                                  margin:
                                      EdgeInsets.symmetric(horizontal: 15.w),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10.h, horizontal: 10.w),
                                  child: VectorGridView())),
                          TabBar(
                            isScrollable: false,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(fontSize: 12),
                            unselectedLabelStyle: TextStyle(fontSize: 12),
                            labelColor: Colors.black,
                            unselectedLabelColor: mdGrey400,
                            indicatorColor: colorPrimary,
                            controller: _tabController,
                            splashFactory: InkRipple.splashFactory,
                            overlayColor:
                                MaterialStateProperty.resolveWith<Color?>(
                              (states) => states.contains(MaterialState.pressed)
                                  ? dividerColor
                                  : null,
                            ),
                            tabs: [
                              Tab(
                                  key: const ValueKey('tab_speed'),
                                  text: l10n.speedTitle),
                              Tab(
                                  key: const ValueKey('tab_transition'),
                                  text: l10n.transitionTitle),
                              Tab(
                                  key: const ValueKey('tab_effects'),
                                  text: l10n.effectsTitle),
                              Tab(
                                  key: const ValueKey('tab_animation'),
                                  text: l10n.animation),
                            ],
                          ),
                          SizedBox(
                            height: 350.h,
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: _tabController,
                              children: [
                                GestureDetector(
                                  onPanDown: (_) =>
                                      setState(() => isDialInteracting = true),
                                  onPanCancel: () =>
                                      setState(() => isDialInteracting = false),
                                  onPanEnd: (_) =>
                                      setState(() => isDialInteracting = false),
                                  child: RadialDial(),
                                ),
                                const TransitionTab(),
                                const EffectTab(),
                                const AnimationTab(),
                              ],
                            ),
                          ),

                          // Add a spacer so last content isn't hidden behind the floating buttons
                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom +
                                  110.h),
                        ],
                      ),
                    ),

                    // Floating bottom buttons (overlay) so they don't push or block content
                    Positioned(
                      left: 16.w,
                      right: 16.w,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
                      child: Consumer<AnimationBadgeProvider>(
                        builder: (context, animationProvider, _) {
                          final isSpecial =
                              animationProvider.isSpecialAnimationSelected();

                          if (isSpecial) {
                            // Only Transfer button (for special animations)
                            return SizedBox(
                              height: 24.h,
                              child: GestureDetector(
                                onTap: () async {
                                  await animationProvider
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
                                },
                                child: Container(
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
                            );
                          } else {
                            // Save + Transfer buttons (side by side, expanded)
                            return Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (inlineimagecontroller.text
                                          .trim()
                                          .isEmpty) {
                                        ToastUtils().showToast(
                                            "Please enter a message");
                                        return;
                                      }

                                      if (widget.savedBadgeFilename != null) {
                                        // Update existing badge
                                        SavedBadgeProvider savedBadgeProvider =
                                            SavedBadgeProvider();
                                        String baseFilename =
                                            widget.savedBadgeFilename!;
                                        if (baseFilename.endsWith('.json')) {
                                          baseFilename = baseFilename.substring(
                                              0, baseFilename.length - 5);
                                        }

                                        await savedBadgeProvider
                                            .updateBadgeData(
                                          baseFilename,
                                          inlineimagecontroller.text,
                                          animationProvider
                                              .isEffectActive(FlashEffect()),
                                          animationProvider
                                              .isEffectActive(MarqueeEffect()),
                                          animationProvider.isEffectActive(
                                              InvertLEDEffect()),
                                          speedDialProvider.getOuterValue(),
                                          animationProvider
                                                  .getAnimationIndex() ??
                                              1,
                                        );

                                        ToastUtils().showToast(
                                            "Badge Updated Successfully");
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/savedBadge',
                                          (route) => false,
                                        );
                                      } else {
                                        // Save new badge dialog
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
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        color: mdGrey400,
                                      ),
                                      child: Text(l10n.saveButton),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      await animationProvider
                                          .handleAnimationTransfer(
                                        badgeData: badgeData,
                                        inlineImageProvider:
                                            inlineImageProvider,
                                        speedDialProvider: speedDialProvider,
                                        flash: animationProvider
                                            .isEffectActive(FlashEffect()),
                                        marquee: animationProvider
                                            .isEffectActive(MarqueeEffect()),
                                        invert: animationProvider
                                            .isEffectActive(InvertLEDEffect()),
                                        context: context,
                                      );
                                    },
                                    child: Container(
                                      height: 32.h,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        color: mdGrey400,
                                      ),
                                      child: Text(l10n.transferButton),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              scaffoldKey: const Key(homeScreenTitleKey),
            ),
          ),
        );
      },
    );
  }

  void handleTextChange() {
    final currentText = inlineimagecontroller.text;
    final selection = inlineimagecontroller.selection;

    // Always reset to text animation if a special animation is selected and user types
    if (animationProvider.isSpecialAnimationSelected() &&
        currentText.isNotEmpty) {
      animationProvider.resetToTextAnimation();
      animationProvider.badgeAnimation(currentText, Converters(),
          animationProvider.isEffectActive(InvertLEDEffect()));
      setState(() {}); // Ensure UI updates
    }

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
  }

  void _controllerListner() {
    animationProvider.badgeAnimation(
      inlineImageProvider.getController().text,
      Converters(),
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
