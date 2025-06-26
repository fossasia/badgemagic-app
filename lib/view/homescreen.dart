<<<<<<< langunage-support
import 'dart:async';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/utils/badge_text_storage.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  // Add parameters for saved badge data when editing
  final Map<String, dynamic>? savedBadgeData;
  final String? savedBadgeFilename;

  const HomeScreen({
    super.key,
    this.savedBadgeData,
    this.savedBadgeFilename,
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
  AnimationBadgeProvider animationProvider = AnimationBadgeProvider();
  late SpeedDialProvider speedDialProvider;
  BadgeMessageProvider badgeData = BadgeMessageProvider();
  ImageUtils imageUtils = ImageUtils();
  InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  bool isPrefixIconClicked = false;
  int textfieldLength = 0;
  String previousText = '';
  final TextEditingController inlineimagecontroller =
      GetIt.instance.get<InlineImageProvider>().getController();
  bool isDialInteracting = false;
  String errorVal = "";

  @override
  void initState() {
    inlineimagecontroller.addListener(handleTextChange);
    _setPortraitOrientation();
    speedDialProvider = SpeedDialProvider(animationProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      inlineImageProvider.setContext(context);

      // Apply saved badge data if we're editing a saved badge
      if (widget.savedBadgeData != null) {
        await _applySavedBadgeData();
      }
    });
    _startImageCaching();
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _applySavedBadgeData() async {
    await SavedBadgeProvider().applySavedBadgeDataToUI(
      savedData: widget.savedBadgeData!,
      savedBadgeFilename: widget.savedBadgeFilename,
      animationProvider: animationProvider,
      speedDialProvider: speedDialProvider,
      inlineimagecontroller: inlineimagecontroller,
      context: context,
    );
    // Set the text field for editing
    if (widget.savedBadgeFilename != null) {
      String badgeText =
          await BadgeTextStorage.getOriginalText(widget.savedBadgeFilename!);
      if (badgeText.isEmpty) {
        badgeText = widget.savedBadgeFilename!
            .substring(0, widget.savedBadgeFilename!.length - 5);
        if (badgeText.contains(":") && badgeText.contains("-")) {
          badgeText = "Hello"; // Default text for timestamp filenames
        }
      }
      inlineimagecontroller.text = badgeText;
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
    inlineimagecontroller.removeListener(handleTextChange);
    animationProvider.stopAnimation();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnimationBadgeProvider>(
          create: (context) => animationProvider,
        ),
        ChangeNotifierProvider<SpeedDialProvider>(
          create: (context) {
            inlineImageProvider.getController().addListener(_controllerListner);
            return speedDialProvider;
          },
        ),
      ],
      child: DefaultTabController(
          length: 3,
          child: CommonScaffold(
            index: 0,
            title: AppLocalizations.of(context)?.appTitle ?? 'Badge Magic',
            body: SafeArea(
              child: SingleChildScrollView(
                physics: isDialInteracting
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: Column(
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
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            prefixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isPrefixIconClicked = !isPrefixIconClicked;
                                });
                              },
                              icon: const Icon(Icons.tag_faces_outlined),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.r)),
                              borderSide: BorderSide(color: colorPrimary),
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
                            margin: EdgeInsets.symmetric(horizontal: 15.w),
                            padding: EdgeInsets.symmetric(
                                vertical: 10.h, horizontal: 10.w),
                            child: VectorGridView())),
                    TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: mdGrey400,
                      indicatorColor: colorPrimary,
                      controller: _tabController,
                      splashFactory: InkRipple.splashFactory,
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return dividerColor;
                          }
                          return null;
                        },
                      ),
                      tabs: [
                        Tab(
                            text: AppLocalizations.of(context)?.tabSpeed ??
                                'Speed'),
                        Tab(
                            text: AppLocalizations.of(context)?.tabAnimation ??
                                'Animation'),
                        Tab(
                            text: AppLocalizations.of(context)?.tabEffects ??
                                'Effects'),
                      ],
                    ),
                    SizedBox(
                      height: 250.h, // Adjust the height dynamically
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          GestureDetector(
                              onPanDown: (_) {
                                // Enter interaction mode to stop main scrolling
                                setState(() => isDialInteracting = true);
                              },
                              onPanCancel: () {
                                // Exit interaction mode if interaction is cancelled
                                setState(() => isDialInteracting = false);
                              },
                              onPanEnd: (_) {
                                // Re-enable main scroll when done interacting
                                setState(() => isDialInteracting = false);
                              },
                              child: RadialDial()),
                          AnimationTab(),
                          EffectTab(),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  if (inlineImageProvider
                                      .getController()
                                      .text
                                      .isEmpty) {
                                    ToastUtils().showToast(
                                        AppLocalizations.of(context)
                                                ?.pleaseEnterMessage ??
                                            "Please enter a message");
                                    return;
                                  }
                                  // If we're editing an existing badge, update it instead of showing save dialog
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
                                        baseFilename, // Pass the filename without .json extension
                                        inlineImageProvider
                                            .getController()
                                            .text,
                                        animationProvider
                                            .isEffectActive(FlashEffect()),
                                        animationProvider
                                            .isEffectActive(MarqueeEffect()),
                                        animationProvider
                                            .isEffectActive(InvertLEDEffect()),
                                        speedDialProvider.getOuterValue(),
                                        animationProvider.getAnimationIndex() ??
                                            1);
                                    ToastUtils().showToast(
                                        AppLocalizations.of(context)
                                                ?.badgeUpdated ??
                                            "Badge Updated Successfully");
                                  } else {
                                    // Show save dialog for new badges
                                    showDialog(
                                        context: this.context,
                                        builder: (context) {
                                          return SaveBadgeDialog(
                                            speed: speedDialProvider,
                                            animationProvider:
                                                animationProvider,
                                            textController: inlineImageProvider
                                                .getController(),
                                            isInverse: animationProvider
                                                .isEffectActive(
                                                    InvertLEDEffect()),
                                          );
                                        });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 33.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.r),
                                    color: mdGrey400,
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)?.save ??
                                          'Save'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100.w,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  badgeData.checkAndTransfer(
                                      inlineImageProvider.getController().text,
                                      animationProvider
                                          .isEffectActive(FlashEffect()),
                                      animationProvider
                                          .isEffectActive(MarqueeEffect()),
                                      animationProvider
                                          .isEffectActive(InvertLEDEffect()),
                                      speedDialProvider.getOuterValue(),
                                      modeValueMap[animationProvider
                                          .getAnimationIndex()],
                                      null,
                                      false);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.r),
                                    color: mdGrey400,
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)?.transfer ??
                                          'Transfer'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            scaffoldKey: const Key(homeScreenTitleKey),
          )),
    );
  }

  void handleTextChange() {
    final currentText = inlineimagecontroller.text;
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
  }

  void _controllerListner() {
    animationProvider.badgeAnimation(inlineImageProvider.getController().text,
        Converters(), animationProvider.isEffectActive(InvertLEDEffect()));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      inlineimagecontroller.clear();
      previousText = '';
      animationProvider.stopAllAnimations.call(); // If method exists
      animationProvider.initializeAnimation.call(); // If method exists
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      animationProvider.stopAnimation();
    }
  }
}
=======
import 'dart:async';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  late final TabController _tabController;
  late SpeedDialProvider speedDialProvider;
  final AnimationBadgeProvider animationProvider = AnimationBadgeProvider();
  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  final ImageUtils imageUtils = ImageUtils();
  final InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  final TextEditingController inlineimagecontroller =
      GetIt.instance.get<InlineImageProvider>().getController();

  bool isPrefixIconClicked = false;
  bool isDialInteracting = false;
  String previousText = '';
  String _cachedText = ''; // <-- NEW: to cache text on pause

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    inlineimagecontroller.addListener(handleTextChange);
    _setPortraitOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inlineImageProvider.setContext(context);
    });
    _startImageCaching();
    speedDialProvider = SpeedDialProvider(animationProvider);
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
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
    if (state == AppLifecycleState.paused) {
      _cachedText = inlineimagecontroller.text;
      animationProvider.stopAnimation();
    } else if (state == AppLifecycleState.resumed) {
      if (inlineimagecontroller.text.trim().isEmpty &&
          _cachedText.trim().isNotEmpty) {
        inlineimagecontroller.text = _cachedText;
      }
      animationProvider.badgeAnimation(
        inlineimagecontroller.text,
        Converters(),
        animationProvider.isEffectActive(InvertLEDEffect()),
      );
    }
  }

  void _controllerListner() {
    animationProvider.badgeAnimation(
      inlineImageProvider.getController().text,
      Converters(),
      animationProvider.isEffectActive(InvertLEDEffect()),
    );
  }

  void handleTextChange() {
    final currentText = inlineimagecontroller.text;
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
  Widget build(BuildContext context) {
    super.build(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnimationBadgeProvider>(
          create: (_) => animationProvider,
        ),
        ChangeNotifierProvider<SpeedDialProvider>(
          create: (_) {
            inlineimagecontroller.addListener(_controllerListner);
            return speedDialProvider;
          },
        ),
      ],
      child: DefaultTabController(
        length: 3,
        child: CommonScaffold(
          index: 0,
          title: 'Badge Magic',
          scaffoldKey: const Key(homeScreenTitleKey),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: isDialInteracting
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  AnimationBadge(),
                  Container(
                    margin: EdgeInsets.all(15.w),
                    child: Material(
                      color: drawerHeaderTitle,
                      borderRadius: BorderRadius.circular(10.r),
                      elevation: 4,
                      child: ExtendedTextField(
                        controller: inlineimagecontroller,
                        specialTextSpanBuilder: ImageBuilder(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          prefixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isPrefixIconClicked = !isPrefixIconClicked;
                              });
                            },
                            icon: const Icon(Icons.tag_faces_outlined),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.r)),
                            borderSide: BorderSide(color: colorPrimary),
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
                        color: Colors.grey[200],
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 15.w),
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 10.w),
                      child: VectorGridView(),
                    ),
                  ),
                  TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: mdGrey400,
                    indicatorColor: colorPrimary,
                    controller: _tabController,
                    splashFactory: InkRipple.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => states.contains(WidgetState.pressed)
                          ? dividerColor
                          : null,
                    ),
                    tabs: const [
                      Tab(text: 'Speed'),
                      Tab(text: 'Animation'),
                      Tab(text: 'Effects'),
                    ],
                  ),
                  SizedBox(
                    height: 250.h,
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
                        AnimationTab(),
                        EffectTab(),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: GestureDetector(
                          onTap: () {
                            if (inlineimagecontroller.text.trim().isEmpty) {
                              ToastUtils()
                                  .showErrorToast("Please enter a message");
                              return;
                            }
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
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 33.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2.r),
                              color: mdGrey400,
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ),
                      SizedBox(width: 100.w),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: GestureDetector(
                          onTap: () {
                            badgeData.checkAndTransfer(
                              inlineimagecontroller.text,
                              animationProvider.isEffectActive(FlashEffect()),
                              animationProvider.isEffectActive(MarqueeEffect()),
                              animationProvider
                                  .isEffectActive(InvertLEDEffect()),
                              speedDialProvider.getOuterValue(),
                              modeValueMap[
                                  animationProvider.getAnimationIndex()],
                              null,
                              false,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2.r),
                              color: mdGrey400,
                            ),
                            child: const Text('Transfer'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
>>>>>>> development
