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
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
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
    super.initState();

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
          length: 4,
          child: CommonScaffold(
            index: 0,
            title: 'Badge Magic',
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
                      isScrollable: false,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: TextStyle(fontSize: 12),
                      unselectedLabelStyle: TextStyle(fontSize: 12),
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
                        Tab(text: 'Transition'),
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
                          TransitionTab(),
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
                          child: Consumer<AnimationBadgeProvider>(
                            builder: (context, animationProvider, _) {
                              final isSpecial = animationProvider
                                  .isSpecialAnimationSelected();
                              if (isSpecial) {
                                // Only show Transfer button, centered
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20.h),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await animationProvider
                                              .handleAnimationTransfer(
                                            badgeData: badgeData,
                                            inlineImageProvider:
                                                inlineImageProvider,
                                            speedDialProvider:
                                                speedDialProvider,
                                            flash: animationProvider
                                                .isEffectActive(FlashEffect()),
                                            marquee: animationProvider
                                                .isEffectActive(
                                                    MarqueeEffect()),
                                            invert: animationProvider
                                                .isEffectActive(
                                                    InvertLEDEffect()),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 33.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(2.r),
                                            color: mdGrey400,
                                          ),
                                          child: const Text('Transfer'),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Show both Save and Transfer as before
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20.h),
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (inlineimagecontroller.text
                                              .trim()
                                              .isEmpty) {
                                            ToastUtils().showToast(
                                                "Please enter a message");
                                            return;
                                          }
                                          // If we're editing an existing badge, update it instead of showing save dialog
                                          if (widget.savedBadgeFilename !=
                                              null) {
                                            SavedBadgeProvider
                                                savedBadgeProvider =
                                                SavedBadgeProvider();
                                            String baseFilename =
                                                widget.savedBadgeFilename!;
                                            if (baseFilename
                                                .endsWith('.json')) {
                                              baseFilename =
                                                  baseFilename.substring(0,
                                                      baseFilename.length - 5);
                                            }
                                            await savedBadgeProvider
                                                .updateBadgeData(
                                              baseFilename, // Pass the filename without .json extension
                                              inlineimagecontroller.text,
                                              animationProvider.isEffectActive(
                                                  FlashEffect()),
                                              animationProvider.isEffectActive(
                                                  MarqueeEffect()),
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
                                                (route) => false);
                                          } else {
                                            // Show save dialog for new badges
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
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 33.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(2.r),
                                            color: mdGrey400,
                                          ),
                                          child: const Text('Save'),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 100.w),
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20.h),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await animationProvider
                                              .handleAnimationTransfer(
                                            badgeData: badgeData,
                                            inlineImageProvider:
                                                inlineImageProvider,
                                            speedDialProvider:
                                                speedDialProvider,
                                            flash: animationProvider
                                                .isEffectActive(FlashEffect()),
                                            marquee: animationProvider
                                                .isEffectActive(
                                                    MarqueeEffect()),
                                            invert: animationProvider
                                                .isEffectActive(
                                                    InvertLEDEffect()),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(2.r),
                                            color: mdGrey400,
                                          ),
                                          child: const Text('Transfer'),
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
